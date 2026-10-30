minv = 0.1
function onTick()
	ws = input.getNumber(2)
	ad = input.getNumber(1)
	leftinv = false
	rightinv = false
	leftlowering = false
	rightlowering = false
	rightinv = xor(ws<-minv,ad>minv)
	leftinv = xor(ws<-minv,ad<-minv)
	output.setBool(1, leftinv)
	output.setBool(3, rightinv)
end

function xor(a, b)
    return (a and not b) or (not a and b)
end