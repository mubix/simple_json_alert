#!/usr/bin/env ruby

require 'httpclient'
require 'json'
require 'jsonclient'
require 'sqlite3'

def create_alert(filled, capacity, paid, due)
        puts "[-] Creating alert for: Filled: #{filled} Capacity: #{capacity} Paid: #{paid} Due: #{due}"
        alert = JSONClient.new
        # Obtain this via https://ifttt.com/maker_webhooks (after login) then click on Documentation
        target = "https://maker.ifttt.com/trigger/and/with/key/yourkeyhere"
        data = {"value1" => "#{filled}", "value2" => "#{paid}", "value3" => "#{due}"}
        result = alert.post(target, data)
end


def check_db(course)
        changed = false
        filled = course['filled']
        capacity = course['capacity']
        paid = course['paid']
        due = course['due']

        # Create the database and table if they don't exist already
        db = SQLite3::Database.new 'state.db'
        begin
                result = db.execute <<-SQL
                        CREATE TABLE state (
                                filled INT,
                                capacity INT,
                                paid INT,
                                due INT
                        );
                        SQL
        rescue SQLite3::SQLException
                puts "[-] Database Exists"
        end

        # Check if row already exists
        result = db.execute 'select * from state limit 1';
        if result == [] # Empty array
                # Inserting initial state
                puts "[!] Creating initial state..."
                db.execute("insert into state (filled, capacity, paid, due) values (?, ?, ?, ?)",
                        [filled, capacity, paid, due])
        else
                # Check for differences
                puts "[-] Checking for changes..."
                puts "[-] Current state: Filled: #{result[0][0]} Capacity: #{result[0][1]} Paid: #{result[0][2]} Due: #{result[0][3]}"
                puts "[-] New state:     Filled: #{filled} Capacity: #{capacity} Paid: #{paid} Due: #{due}"
                if filled != result[0][0]
                        changed = true
                        db.execute("update state set filled = #{filled}")
                end
                if capacity != result[0][1]
                        changed = true
                        db.execute("update state set capacity = #{capacity}")
                end
                if paid != result[0][2]
                        changed = true
                        db.execute("update state set paid = #{paid}")
                end
                if due != result[0][3]
                        changed = true
                        db.execute("update state set due = #{due}")
                end
        end
        return changed
end


http = HTTPClient.new

base = "http://location.for.json.blob/here.json"
user = 'UserName'
pass = 'Password'

http.set_auth(base, user, pass)

response = http.get("#{base}")

info = JSON.parse(response.body)

info.each do |course|
        # Name of the class to look for in the JSON blob
        if course["name"] == "Ability Driven Red Teaming: August 3-6"
                changed = check_db(course)
                if changed
                        puts "[!] State changed!"
                        create_alert(course['filled'], course['capacity'], course['paid'], course['due'])
                else
                        puts "[-] Everything is normal..."
                end
        end
end
