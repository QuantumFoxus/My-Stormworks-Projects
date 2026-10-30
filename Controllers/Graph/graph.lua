a=0
arr={}
maxp=1200
vert_min = 0
vert_max = 1
function onTick()
	a=a+math.random(100)-50
end
function onDraw()
	drawGraph(a)
end
function lerp(s, f, time)
	return s + (f - s) * time
end
function clamp(a,minV,maxV)
	return a>maxV and maxV or a<minV and minV or a
end
function drawGraph(val)
	if #arr>maxp-1 then
		arr[#arr]=val
		for i=1,#arr-1,1 do
			arr[i]=arr[i+1]
		end
	else
		arr[#arr+1]=val
	end
	w=screen.getWidth()
	h=screen.getHeight()
	graph_max=arr[1]
	graph_min=arr[1]
	for i=1,#arr,1 do
		if arr[i] > graph_max then
			graph_max = arr[i]
		end
		if arr[i] < graph_min then
			graph_min = arr[i]
		end
	end
	screen.sc(10,10,10)
	screen.drawRectF(0,0,w-1,h-1)
	screen.sc(255,255,255)
	screen.drawText(2,h*0.1-8,"max:"..math.floor(graph_max*1000)/1000)
	screen.drawText(2,h*0.9+3,"min:"..math.floor(graph_min*1000)/1000)
	for i=1,w-4,8 do
		screen.drawLine(i,h*0.9+1,i+4,h*0.9+1)
		screen.drawLine(i,h*0.1-1,i+4,h*0.1-1)
	end
	screen.sc(255,0,0)
	for i=1,#arr-1,1 do
		local x1=i/maxp*w
		local x2=(i+1)/maxp*w
		local y1=(arr[i]-graph_min)/(graph_max-graph_min)*0.8+0.1
		local y2=(arr[i+1]-graph_min)/(graph_max-graph_min)*0.8+0.1
		y1=clamp(y1,0.1,0.9)
		y2=clamp(y2,0.1,0.9)
		y1=lerp(h,0,y1)
		y2=lerp(h,0,y2)
		screen.drawLine(x1,y1,x2,y2)
	end	
end