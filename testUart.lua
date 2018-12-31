--- 模块功能：串口功能测试(非TASK版，串口帧有自定义的结构)
-- @author openLuat
-- @module uart.testUart
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

require"utils"
require"pm"
require"mqttOutMsg"
require"misc"
require "mqttTask"
require"mqttInMsg"
require "update"



--串口ID,1对应uart1,2对应uart2
local UART_ID = 1
--帧头类型以及帧尾

local rdbuf = ""

local function cbFnc(downloadResult)
	if  downloadResult then 
		write("#4 y1$")
	else
		write("#4 y2$")
	end 
	
	sys.timerStart(sys.restart,10000,"sysupdate")	
end
--[[
函数名：parse
功能  ：按照帧结构解析处理一条完整的帧数据
参数  ：
        data：所有未处理的数据
返回值：第一个返回值是一条完整帧报文的处理结果，第二个返回值是未处理的数据
]]
local function parse(data)


   if not data then return end

--   local tail = string.find(data,string.char(0x24))
--    if not tail then return false,data end

   local cmdtyp, cmdcon  = string.byte(data,1,2)
	
--  log.info("testUart.parse",data:toHex(),cmdtyp,body:toHex())


	if cmdtyp == 0x02 then
		if cmdcon == 0x02 then
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." autoCurrent:off")
		elseif cmdcon == 0x01 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." autoCurrent:on")
		end
	elseif cmdtyp == 0x03 then
		if cmdcon == 0x02 then
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." sleepCurrent:off")
		elseif cmdcon == 0x01 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." sleepCurrent:on")
		end
	elseif cmdtyp == 0x04 then
		if cmdcon == 0x01 then
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." gearCurrent:min")
		elseif cmdcon == 0x02 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." gearCurrent:normal")
		elseif cmdcon == 0x03 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." gearCurrent:max")
		elseif cmdcon == 0x04 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." gearCurrent:four")
		end
	elseif cmdtyp == 0x05 then
		if cmdcon == 0x02 then
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." ionCurrent:off")
		elseif cmdcon == 0x01 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." ionCurrent:on")
		end
	elseif cmdtyp == 0x06 then
		if cmdcon == 0x02 then
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." sterilizeCurrent:off")
		elseif cmdcon == 0x01 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." sterilizeCurrent:on")
		end
	elseif cmdtyp == 0x08 then
		if cmdcon == 0x02 then
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." reset:0")
		elseif cmdcon == 0x01 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." reset:1")
		end
	elseif cmdtyp == 0x09 then
		if cmdcon == 0x02 then
			mqttOutMsg.pubmsg("id:"..mqttTask.imei.." lockCurrent:off")
		elseif cmdcon == 0x01 then
		    mqttOutMsg.pubmsg("id:"..mqttTask.imei.." lockCurrent:on")
		end
	elseif cmdtyp == 0x0c then
		if cmdcon == 0x01 then
			mqttOutMsg.puberror("id:"..mqttTask.imei.." status:500 ")
		end
	elseif cmdtyp == 0x0d then
			mqttOutMsg.pubstatus("id:"..mqttTask.imei.." lifevalue:"..cmdcon)
	elseif cmdtyp == 0x0e then
		if cmdcon == 0x01 then
			write("#0 "..mqttTask.imei.."$")
		end
	elseif cmdtyp == 0x11 then
		if cmdcon == 0x01 then
		mqttOutMsg.pubmsg("id:"..mqttTask.imei.." start update")
		update.request(cbFnc)
		end
	elseif cmdtyp == 0x12 then
		
		if cmdcon == 0x11 then
			mcuonoff = 1
		end
		
		if cmdcon == 0x12 then
			mcuonoff = 0
			if mqttInMsg.onoff == 1 then
			testUart.write("#4 11$")
			end							
		end		
		
		

	end

    data = 0


end



--[[
函数名：proc
功能  ：处理从串口读到的数据
参数  ：
        data：当前一次从串口读到的数据
返回值：无

local function proc(data)
    if not data or string.len(data) == 0 then return end
    --追加到缓冲区

	rdbuf = rdbuf..data

    local result,unproc
    unproc = rdbuf
    --根据帧结构循环解析未处理过的数据
    while true do
        result,unproc = parse(unproc)
        if not unproc or unproc == "" or not result then
            break
        end
    end

    rdbuf = unproc or ""
end
]]
--[[
函数名：read
功能  ：读取串口接收到的数据
参数  ：无
返回值：无
]]
local function read()
    local data = 0
    --底层core中，串口收到数据时：
    --如果接收缓冲区为空，则会以中断方式通知Lua脚本收到了新数据；
    --如果接收缓冲器不为空，则不会通知Lua脚本
    --所以Lua脚本中收到中断读串口数据时，每次都要把接收缓冲区中的数据全部读出，这样才能保证底层core中的新数据中断上来，此read函数中的while语句中就保证了这一点
    while true do
        data = uart.read(UART_ID,"*l")
        if not data or string.len(data) == 0 then break end
        --打开下面的打印会耗时
        --log.info("testUart.read bin",data)
        --log.info("testUart.read hex",data:toHex())
        ---proc(data)
		parse(data)
    end
end

--[[
函数名：write
功能  ：通过串口发送数据
参数  ：
        s：要发送的数据
返回值：无
]]
function write(s)
    --log.info("testUart.write",s)
    uart.write(UART_ID,s)
end

local function writeOk()
    --log.info("testUart.writeOk")
end


--保持系统处于唤醒状态，此处只是为了测试需要，所以此模块没有地方调用pm.sleep("testUart")休眠，不会进入低功耗休眠状态
--在开发“要求功耗低”的项目时，一定要想办法保证pm.wake("testUart")后，在不需要串口时调用pm.sleep("testUart")
pm.wake("testUart")
--注册串口的数据接收函数，串口收到数据后，会以中断方式，调用read接口读取数据
uart.on(UART_ID,"receive",read)
--注册串口的数据发送通知函数
uart.on(UART_ID,"sent",writeOk)

--配置并且打开串口
uart.setup(UART_ID,9600,8,uart.PAR_NONE,uart.STOP_1)
--如果需要打开“串口发送数据完成后，通过异步消息通知”的功能，则使用下面的这行setup，注释掉上面的一行setup
--uart.setup(UART_ID,9600,8,uart.PAR_NONE,uart.STOP_1,nil,1)
