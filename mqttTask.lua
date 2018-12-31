--- 模块功能：MQTT客户端处理框架
-- @author openLuat
-- @module mqtt.mqttTask
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(...,package.seeall)

require "misc"
require "mqtt"
require "mqttOutMsg"
require "mqttInMsg"
require "testUart"
require "net"

local ready = false
mqttflag = 0
local breath = 0
offline = 0
local mcuonoffcounter=0

local function loopbreath()

	if mqttflag ==1  then
		if breath >59 then
			breath = 0
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." status:"..mqttInMsg.onoff)
		else
			breath =breath+1
		end
		
		if mqttInMsg.settimeonoff == 1 then

			if mqttInMsg.opentimebuff > 0  then
			mqttInMsg.opentimebuff = mqttInMsg.opentimebuff -1
			else
			mqttInMsg.onoff = 0
			mqttInMsg.settimeonoff = 0
			testUart.write("#4 12$")
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." t:"..mqttInMsg.opentime.." p:on status:201")		
			end

		end		
		
		offline = 0
		

		
		if mqttInMsg.onoff == 0 then
	
			if  testUart.mcuonoff == 1 then
				mcuonoffcounter = mcuonoffcounter + 1
				if mcuonoffcounter >6 then
					mcuonoffcounter = 0
					testUart.write("#4 12$")
				end
			
			end
		else
			mcuonoffcounter =0
		end
		
		
	end
	


end

local function erroroff()
	if mqttflag ~= 1 then

		if offline < mqttInMsg.errortimebuff  then
			offline = offline + 1
		else
			offline = 0
			testUart.write("#4 12$")
			mqttInMsg.onoff = 0
		end
	end

end



local function gprsbreath()

    local csq = net.getRssi()
   if mqttflag == 1  then
   testUart.write("#2 2 "..csq.."$")
   else
   testUart.write("#2 1 "..csq.."$")
   end

end


--- MQTT连接是否处于激活状态
-- @return 激活状态返回true，非激活状态返回false
-- @usage mqttTask.isReady()
function isReady()
    return ready
end

--启动MQTT客户端任务
sys.taskInit(
    function()
        while true do
		sys.timerLoopStart(gprsbreath,2000)
		sys.timerLoopStart(erroroff,1000)

            if not socket.isReady() then
                --等待网络环境准备就绪，超时时间是5分钟
                sys.waitUntil("IP_READY_IND",300000)
            end

            if socket.isReady() then
               imei = misc.getImei()

                local mqttClient = mqtt.client(imei,600,"sedevice","956497e59024554d38d14456984d8551dec8254d")
                --阻塞至成功
                --ssl连接，打开mqttClient:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})
                if mqttClient:connect("www.it-rayko.com",1883,"tcp") then
                    ready = true
                    --订阅主题
                    if mqttClient:subscribe({["control/"..imei]=0, ["assist/"..imei]=0, ["reset/"..imei]=0}) then
						mqttOutMsg.pubmsg("id:"..mqttTask.imei.." status:200")
						mqttOutMsg.pubmsg("id:"..mqttTask.imei.." network:2G")
						mqttOutMsg.pubmsg("id:"..mqttTask.imei.." status:800")
						sys.timerLoopStart(loopbreath,1000)
						mqttflag = 1
                        --循环处理接收和发送的数据
                        while true do
                            if not mqttInMsg.proc(mqttClient) then log.error("mqttTask.mqttInMsg.proc error") break end
                            if not mqttOutMsg.proc(mqttClient) then log.error("mqttTask.mqttOutMsg proc error") break end
                        end


                    end

                    ready = false
                end
                --断开MQTT连接
				mqttflag = 0
                mqttClient:disconnect()
                sys.wait(5000)
            else
                --进入飞行模式，20秒之后，退出飞行模式
                net.switchFly(true)
                sys.wait(20000)
                net.switchFly(false)
            end
        end
    end
)
