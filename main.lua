
function reset_game_state()
	started = false
	t = 0
	next_circ_idx = 1
	score = 0
	hits = 0
	misses = 0
	combo = 0
	combo_max = 0
	all_circs = {}
	for i = 1, 100 do
		all_circs[#all_circs + 1] = {
			beat_start=3 + i,
			x=love.math.random(GAMEPLAY_LEFT, GAMEPLAY_RIGHT),
			y=love.math.random(GAMEPLAY_TOP, GAMEPLAY_BOTTOM),
			size=50 + 20 * love.math.random(0, 1),
			count_in=2,
		}
	end
	current_circs = {}
	past_circs = {}
	hit_msgs = {}
	can_reset_time = 9999999  -- set to t+delay when finish all circles
end


function love.load()
	WIDTH = 1280
	HEIGHT = 720
	GAMEPLAY_LEFT = math.floor(WIDTH * 0.1)
	GAMEPLAY_RIGHT = WIDTH - GAMEPLAY_LEFT
	GAMEPLAY_TOP = math.floor(HEIGHT * 0.1)
	GAMEPLAY_BOTTOM = HEIGHT - GAMEPLAY_TOP
	love.window.setMode(WIDTH, HEIGHT)
	love.window.setTitle("Circles and Chill")
	
	CURSOR_SIZE = 15
	CURSOR_ALPHA = 0.7
	BPM = 180
	SECONDS_PER_BEAT = 60 / BPM
	HIT_FADEOUT_BEATS = 2
	
	TITLE_FONT = love.graphics.newFont(96)
	BASE_FONT = love.graphics.newFont(32)
	HIT_MSG_FONT = love.graphics.newFont(96)
	
	-- sound stuff
	HIT_SOUND = love.audio.newSource("sounds/263133__pan14__tone-beep.wav", "static")
	MISS_SOUND = love.audio.newSource("sounds/399934__waveplay__short-click-snap-perc.wav", "static")
	MISS_SOUND:setVolume(0.5)

	-- simple way to allow sounds to overlap, may break at high BPM
	-- (esp w/ the "short-click-snap-perc" miss sound)
	hit_sounds = {HIT_SOUND:clone(), HIT_SOUND:clone(), HIT_SOUND:clone(), HIT_SOUND:clone()}
	miss_sounds = {MISS_SOUND:clone(), MISS_SOUND:clone(), MISS_SOUND:clone(), MISS_SOUND:clone()}
	hit_sound_idx = 1
	miss_sound_idx = 1
	
	PLAY_AGAIN_BUTTON = {
		left = WIDTH / 2 - 120,
		right = WIDTH / 2 + 120,
		top = GAMEPLAY_BOTTOM - 130,
		bottom = GAMEPLAY_BOTTOM - 30,
	}
	PLAY_AGAIN_BUTTON.width = PLAY_AGAIN_BUTTON.right - PLAY_AGAIN_BUTTON.left
	PLAY_AGAIN_BUTTON.height = PLAY_AGAIN_BUTTON.bottom - PLAY_AGAIN_BUTTON.top
	
	-- setup gameplay variables
	reset_game_state()
end


function play_hit_sound()
	hit_sounds[hit_sound_idx]:play()
	hit_sound_idx = (hit_sound_idx - 1) % #hit_sounds + 1
end

function play_miss_sound()
	miss_sounds[miss_sound_idx]:play()
	miss_sound_idx = (miss_sound_idx - 1) % #miss_sounds + 1
end


function love.draw()
	if not started then
		love.graphics.setFont(TITLE_FONT)
		love.graphics.printf(
			"CIRCLES AND CHILL",
			GAMEPLAY_LEFT, GAMEPLAY_TOP + 200, GAMEPLAY_RIGHT - GAMEPLAY_LEFT,
			"center"
		)
		love.graphics.setFont(BASE_FONT)
		love.graphics.printf(
			"click to start",
			GAMEPLAY_LEFT, GAMEPLAY_TOP + 400, GAMEPLAY_RIGHT - GAMEPLAY_LEFT,
			"center"
		)
		return
	end
	love.graphics.setFont(BASE_FONT)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Score: " .. tostring(score), 50, 10)
	if not (hits + misses == 0) then
		if misses == 0 then
			acc_str = "Perfect!"
		else
			acc_str = string.format("%.1f", 100 * hits / (hits + misses)) .. "%"
		end
	else
		acc_str = "..."
	end
	love.graphics.print("Accuracy: " .. acc_str, 50, 50)
	love.graphics.print("Combo: " .. tostring(combo), 400, 10)
	love.graphics.print("Highest: " .. tostring(combo_max), 400, 50)
	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 1100, 10)
	love.graphics.print("Beat: " .. tostring(beat_num), 1100, 50)
	
	if t > can_reset_time then
		love.graphics.setColor(1, 0, 0, 0.2)
		love.graphics.rectangle(
			"fill",
			PLAY_AGAIN_BUTTON.left, PLAY_AGAIN_BUTTON.top,
			PLAY_AGAIN_BUTTON.width, PLAY_AGAIN_BUTTON.height
		)
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(
			"Play again?",
			GAMEPLAY_LEFT, GAMEPLAY_BOTTOM - 100, GAMEPLAY_RIGHT - GAMEPLAY_LEFT,
			"center"
		)
	end
	
	love.graphics.setFont(HIT_MSG_FONT)
	for i, msg in ipairs(hit_msgs) do
		love.graphics.setColor(
			msg.color.r, msg.color.g, msg.color.b,
			msg.color.a * msg.timer / msg.duration
		)
		love.graphics.printf(
			msg.msg,
			GAMEPLAY_LEFT + msg.x,
			GAMEPLAY_TOP + msg.y,
			GAMEPLAY_RIGHT - GAMEPLAY_LEFT,
			"center"
		)
	end
	for i, circ in ipairs(current_circs) do
		scale_amt = circ.timer / (SECONDS_PER_BEAT * circ.count_in)
		love.graphics.setColor(1, 1, 1, 1 - scale_amt)
		love.graphics.circle("fill", circ.x, circ.y, circ.size)
		love.graphics.setColor(0.5, 0.5, 0.5, 1 - scale_amt)
		love.graphics.setLineWidth(3)
		love.graphics.circle("line", circ.x, circ.y, circ.size * (1 + scale_amt))
	end
	for i, circ in ipairs(past_circs) do
		if circ.hit then
			love.graphics.setColor(0, 1, 0, circ.timer / HIT_FADEOUT_BEATS)
			love.graphics.setLineWidth(circ.size / 10)
			--love.graphics.circle("line", circ.x, circ.y, circ.size * 0.3)  -- circle
			love.graphics.line( -- tick
				circ.x - circ.size/2, circ.y,
				circ.x - circ.size/6, circ.y + circ.size/2,
				circ.x + circ.size/2, circ.y - circ.size/2
			)
		else
			love.graphics.setColor(1, 0, 0, circ.timer / HIT_FADEOUT_BEATS)
			love.graphics.setLineWidth(circ.size / 10)
			love.graphics.line(  -- X
				circ.x - circ.size/2, circ.y - circ.size/2,
				circ.x + circ.size/2, circ.y + circ.size/2
			)
			love.graphics.line(  -- X
				circ.x - circ.size/2, circ.y + circ.size/2,
				circ.x + circ.size/2, circ.y - circ.size/2
			)
		end
		--love.graphics.circle("fill", circ.x, circ.y, circ.size)  -- old ver
	end
	mouse_x, mouse_y = love.mouse.getPosition()
	love.graphics.setColor(0.4, 1, 0.3, CURSOR_ALPHA)
	love.graphics.circle("fill", mouse_x, mouse_y, CURSOR_SIZE)
	love.graphics.setColor(1, 1, 1)
	love.graphics.setLineWidth(CURSOR_SIZE / 8)
	love.graphics.circle("line", mouse_x, mouse_y, CURSOR_SIZE)
	love.graphics.circle("fill", mouse_x, mouse_y, 2)
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
				if combo > combo_max then
					combo_max = combo
				end
				score = score + 10 + combo
				hit_msgs[#hit_msgs + 1] = {
					timer = SECONDS_PER_BEAT * 3,
					duration = 3,
					msg = "COMBO +" .. tostring(combo) .. "!",
					x = love.math.random(-100, 100),  -- will be "full width"
					y = GAMEPLAY_TOP + love.math.random(0, 200),
					color = {r=1, g=1, b=1, a=0.5},
				}
				play_hit_sound()
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
						y = GAMEPLAY_TOP + 100,
						color = {r=1, g=0, b=0, a=0.7,},
					}
				}
				play_miss_sound()
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
			if next_circ_idx > #all_circs then
				can_reset_time = t + current_circs[#current_circs].timer + 1
			end
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
	if t > can_reset_time then
		if (
			m_x > PLAY_AGAIN_BUTTON.left and m_x < PLAY_AGAIN_BUTTON.right
			and m_y > PLAY_AGAIN_BUTTON.top and m_y < PLAY_AGAIN_BUTTON.bottom
		) then
			reset_game_state()
			started = true
		end
	end
end


function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit()
	end
end