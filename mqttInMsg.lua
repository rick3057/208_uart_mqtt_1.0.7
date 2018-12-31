--- 模块功能：MQTT客户端数据接收处理
-- @author openLuat
-- @module mqtt.mqttInMsg
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(...,package.seeall)
require "mqttTask"
require"misc"
require "testUart"
require "update"
settimeonoff = 0
onoff = 0
opentime = 0
opentimebuff = 0
errortimebuff =120
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttInMsg.proc(mqttClient)
function proc(mqttClient)
    local result,data
    while true do
        result,data = mqttClient:receive(2000)
        --接收到数据
        if result then	
--[[ ]]
			local judgebuff = string.sub(data.payload,1,7)
			if  "p:on t:" == judgebuff then
				opentime = string.sub(data.payload,8,-1)
				opentimebuff = opentime*60
				 
				if(testUart.mcuonoff == 0) then
				testUart.write("#4 11 "..opentime.." $")
				end
				
				settimeonoff = 1
				onoff = 1
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." t:"..opentime.." p:on status:200")
				break
			end

			judgebuff = string.sub(data.payload,1,16)
			if  "welcomeInterval:" == judgebuff then
				local position = string.find(data.payload," ")
				local intervaltime = string.sub(data.payload,17,position-1)
				position = position + 11
				local errortime = string.sub(data.payload,position,-1)
				errortimebuff = errortime * 60
				testUart.write("#4 2 "..intervaltime.." "..errortime.." $")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." welcomeIntervalCurrent:"..intervaltime)
				break
			end


			if  "p:on" == data.payload then
				onoff = 1
				testUart.write("#4 11 9999 $")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." p:on status:200")
				break
			elseif  "p:off" == data.payload  then
				onoff = 0
				testUart.write("#4 12$")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." p:off status:200")
				break
			elseif  "excution:pause" == data.payload  then
				testUart.write("#4 12$")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." status:300")
				break
			elseif  "excution:resume" == data.payload  then
				testUart.write("#4 11$")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." status:301")
				break
			elseif  "sound:max" == data.payload  then
				testUart.write("#4 1 15 $")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." soundCurrent:min")				
				break
			elseif  "sound:normal" == data.payload  then
				testUart.write("#4 1 7 $")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." soundCurrent:normal")			
				break
			elseif  "sound:min" == data.payload  then
				testUart.write("#4 1 2 $")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." soundCurrent:max")			
				break
			elseif  "auto:on" == data.payload  then
				testUart.write("#4 45$")
				break
			elseif  "gear:four" == data.payload  then
				testUart.write("#4 44$")
				break
			elseif  "gear:max" == data.payload  then
				testUart.write("#4 43$")
				break
			elseif  "gear:normal" == data.payload  then
				testUart.write("#4 42$")
			elseif  "gear:min" == data.payload  then
				testUart.write("#4 41$")
				break
			elseif  "sleep:on" == data.payload  then
				testUart.write("#4 51$")
				break
			elseif  "sleep:off" == data.payload  then
				testUart.write("#4 52$")
				break
			elseif  "ion:on" == data.payload  then
				testUart.write("#4 61$")
				break
			elseif  "ion:off" == data.payload  then
				testUart.write("#4 62$")
				break
			elseif  "sterilize:on" == data.payload  then
				testUart.write("#4 71$")
				break
			elseif  "sterilize:off" == data.payload  then
				testUart.write("#4 72$")
				break
			elseif  "lock:on" == data.payload  then
				testUart.write("#4 81$")
				break
			elseif  "lock:off" == data.payload  then
				testUart.write("#4 82$")
				break
			elseif  "welcome:on" == data.payload  then
				testUart.write("#4 91$")				
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." welcomeCurrent:on")
				break
			elseif  "welcome:off" == data.payload  then
				testUart.write("#4 92$")
				mqttOutMsg.pubmsg("id:"..mqttTask.imei.." welcomeCurrent:off")
				break
			elseif  "act:reset" == data.payload  then
				testUart.write("#4 a1$")
				break
			elseif  "wifion:1" == data.payload  then
				testUart.write("#4 z2$")
				break	

			end



            --如果mqttOutMsg中有等待发送的数据，则立即退出本循环
            --if mqttOutMsg.waitForSend() then return true end
        else
            break
        end
    end

    return result or data=="timeout"
end
