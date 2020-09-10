
function love.load()
	CURSOR_SIZE = 10
	BPM = 120
	SECONDS_PER_BEAT = 60 / BPM
	HIT_FADEOUT_BEATS = 2
	started = false
	t = 0
	next_circ_idx = 1
	score = 0
	hits = 0
	misses = 0
	combo = 0
	all_circs = {
		-- currently, u need to order these
		{beat_start=2, x=50, y=50, size=30, count_in=2},
		{beat_start=3, x=75, y=50, size=30, count_in=2},
		{beat_start=4, x=100, y=50, size=30, count_in=2},
		{beat_start=5, x=100, y=50, size=50, count_in=2},
		{beat_start=6, x=500, y=500, size=50, count_in=2},
		{beat_start=7, x=300, y=300, size=50, count_in=2},
		{beat_start=10, x=300, y=300, size=50, count_in=2},
		{beat_start=11, x=300, y=300, size=50, count_in=2},
		{beat_start=12, x=200, y=300, size=50, count_in=2},
		{beat_start=13, x=200, y=200, size=50, count_in=2},
		{beat_start=14, x=200, y=400, size=50, count_in=2},
		{beat_start=15, x=400, y=400, size=50, count_in=2},
		{beat_start=16, x=500, y=400, size=20, count_in=2},
	}
	current_circs = {}
	past_circs = {}
	hit_msgs = {}
	BASE_FONT = love.graphics.newFont(32)
	HIT_MSG_FONT = love.graphics.newFont(96)
end


function love.draw()
	love.graphics.setFont(BASE_FONT)
	if not started then
		love.graphics.print("click to start", 100, 100)
		return
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 600, 10)
	love.graphics.print("score: " .. tostring(score), 100, 10)
	if not (hits + misses == 0) then
		if misses == 0 then
			acc_str = "Perfect!"
		else
			acc_str = string.format("%.1f", 100 * hits / (hits + misses)) .. "%"
		end
	else
		acc_str = "..."
	end
	love.graphics.print("accuracy: " .. acc_str, 100, 50)
	love.graphics.print("combo: " .. tostring(combo), 300, 10)
	love.graphics.print("beat " .. tostring(beat_num), 600, 50)
	--love.graphics.print("sdfsdf " .. tostring(#current_circs), 500, 100)
	love.graphics.setFont(HIT_MSG_FONT)
	for i, msg in ipairs(hit_msgs) do
		love.graphics.setColor(
			msg.color.r, msg.color.g, msg.color.b,
			msg.color.a * msg.timer / msg.duration
		)
		love.graphics.printf(msg.msg, msg.x, msg.y, 800, "center")
	end
	for i, circ in ipairs(current_circs) do
		scale_amt = circ.timer / (SECONDS_PER_BEAT * circ.count_in)
		love.graphics.setColor(1, 1, 1, 1 - scale_amt)
		love.graphics.circle("fill", circ.x, circ.y, circ.size)
		love.graphics.setColor(0.5, 0.5, 0.5, 1 - scale_amt)
		love.graphics.circle("line", circ.x, circ.y, circ.size * (1 + scale_amt))
	end
	for i, circ in ipairs(past_circs) do
		if circ.hit then
			love.graphics.setColor(0, 1, 0, circ.timer / HIT_FADEOUT_BEATS)
		else
			love.graphics.setColor(1, 0, 0, circ.timer / HIT_FADEOUT_BEATS)
		end
		love.graphics.circle("fill", circ.x, circ.y, circ.size)
	end
	mouse_x, mouse_y = love.mouse.getPosition()
	love.graphics.setColor(1, 0.5, 0.5)
	love.graphics.circle("fill", mouse_x, mouse_y, CURSOR_SIZE)
end


function love.update(dt)
	if not started then
		return
	end
	t = t + dt
	beat_num = math.floor(t / SECONDS_PER_BEAT)
	beat_fraction = t / SECONDS_PER_BEAT - beat_num
	for i, msg in ipairs(hit_msgs) do
		if msg.timer > 0 then
			msg.timer = msg.timer - dt
		else
			table.remove(hit_msgs, i)
		end
	end
	for i, circ in ipairs(current_circs) do
		if circ.timer > 0 then
			circ.timer = circ.timer - dt
		else
			mouse_x, mouse_y = love.mouse.getPosition()
			hit = ((mouse_x - circ.x) ^ 2 + (mouse_y - circ.y) ^ 2) < circ.size ^ 2
			if hit then
				hits = hits + 1
				combo = combo + 1
				score = score + 10 + combo
				hit_msgs[#hit_msgs + 1] = {
					timer = SECONDS_PER_BEAT * 3,
					duration = 3,
					msg = "COMBO +" .. tostring(combo) .. "!",
					x = love.math.random(-100, 100),
					y = 200 + love.math.random(-100, 100),
					color = {r=1, g=1, b=1, a=0.5},
				}
			else
				misses = misses + 1
				score = score - 5
				combo = 0
				hit_msgs = {
					{
						timer = SECONDS_PER_BEAT * 4,
						duration = 4,
						msg = "COMBO FAIL!",
						x = 0,
						y = 200,
						color = {r=1, g=0, b=0, a=0.7,},
					}
				}
			end
			past_circs[#past_circs + 1] = {
				x = circ.x,
				y = circ.y,
				size = circ.size,
				timer = SECONDS_PER_BEAT * HIT_FADEOUT_BEATS,
				hit = hit,
			}
			table.remove(current_circs, i)
		end
	end
	for i, circ in ipairs(past_circs) do
		if circ.timer > 0 then
			circ.timer = circ.timer - dt
		else
			table.remove(past_circs, i)
		end
	end
	next_circ = all_circs[next_circ_idx]
	while not (next_circ == nil) do
		if next_circ.beat_start <= beat_num + next_circ.count_in then
			something_invalid = current_circs[100]
			current_circs[#current_circs + 1] = {
				timer = SECONDS_PER_BEAT * next_circ.count_in,
				count_in = next_circ.count_in,
				x = next_circ.x,
				y = next_circ.y,
				size = next_circ.size,
			}
			next_circ_idx = next_circ_idx + 1
			next_circ = all_circs[next_circ_idx]
		else
			break
		end
	end
end


function love.mousepressed(m_x, m_y, button, istouch, presses)
	if not started then
		started = true
		love.mouse.setVisible(false)
		return
	end
end