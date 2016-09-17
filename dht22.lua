-- cyberde - tweakers.net
DHT= require("dht_lib")

-- ESP-01 GPIO Mapping
PIN = 4;

-- Set MQTT Client
m = mqtt.Client(wifi.sta.getmac(), 120);
mqttbroker = "mqttbroker.local";

function publish()
    DHT.read22(PIN);

    t = DHT.getTemperature();
    h = DHT.getHumidity();
    
    m:publish("sensor/" .. wifi.sta.getmac() .. "/temperature", (t / 10), 2, 0, function(conn) 
        print ("*** Published temperature to broker ***");

        m:publish("sensor/" .. wifi.sta.getmac() .. "/humidity", (h / 10), 2, 0, function(conn) 
            print ("*** Published humidity to broker ***");
        end)
    end)
    
    collectgarbage();
end

function connectToMQTT()
    m:connect(mqttbroker, 1883, 0, function(conn) 
        print ("*** Connected to MQTT broker " .. mqttbroker .. " ***");        
        
        publish();
    end)
end

m:on("connect", function(con)
    print ("*** Connecting to MQTT broker ***");
end)

m:on("offline", function(con) 
    print ("*** MQTT broker offline ***");
    
    tmr.alarm(1, 15000, 0, function()
        connectToMQTT();
    end)
end)

m:on("message", function(conn, topic, data) 
    processCommand(data);
end)

connectToMQTT();

tmr.alarm(0, 300000, 1, function()
    publish();
end);
