use context essentials2021
import reactors as R
import image as I


### TYPE ###

data PlatformLevel:
  | top
  | middle
  | bottom
end

data GameStatus:
  | ongoing
  | transitioning(ticks-left :: Number)
  | game-over
end

type Platform = {
  x :: Number,
  y :: Number,
  dx :: Number,
}

type Egg = {
  x :: Number,
  y :: Number,
  dy :: Number,
  ay :: Number,
  is-airborne :: Boolean,
}

type State = {
  game-status :: GameStatus,
  egg :: Egg,
  current-platform :: PlatformLevel,
  platforms :: List<Platform>,
  score :: Number,
  lives :: Number,
}

### CONSTANT ###

fun random-num(n :: Number) -> Number:
  x = num-random(n)
  y = num-random(1)  
  if y == 0: 0 - x - 3
  else: x + 3
  end
end 

SCREEN-WIDTH = 300
SCREEN-HEIGHT = 500

PLATFORM-WIDTH = 60
PLATFORM-HEIGHT = 10
PLATFORM-COLOR = 'brown'

HALF-PLATFORM-HEIGHT = PLATFORM-HEIGHT / 2
HALF-PLATFORM-WIDTH = PLATFORM-WIDTH / 2

TOP-PLATFORM = {
  x: SCREEN-WIDTH / 2,
  y: 140,
  dx: random-num(5),
}

MIDDLE-PLATFORM = {
  x: SCREEN-WIDTH / 2,
  y: 280,
  dx: random-num(5),
}   

BOTTOM-PLATFORM = {
  x: SCREEN-WIDTH / 2,
  y: 420,
  dx: random-num(5),
}

EGG-RADIUS = 20
EGG-COLOR = 'peach-puff'
EGG-JUMP-HEIGHT = -18

EGG = {
  x: SCREEN-WIDTH / 2, 
  y: BOTTOM-PLATFORM.y - EGG-RADIUS - (PLATFORM-HEIGHT / 2),
  dy: 0,
  ay: 0,
  is-airborne: false,
}

INITIAL-STATE = {
  game-status: ongoing,
  egg: EGG,
  current-platform: bottom,
  platforms: [list: BOTTOM-PLATFORM, MIDDLE-PLATFORM, TOP-PLATFORM],
  score: 0,
  lives: 12,
}

### DRAWING ###

fun draw-egg(state :: State, img :: Image) -> Image:
  egg = circle(EGG-RADIUS, "solid", EGG-COLOR)
  I.place-image(egg, state.egg.x, state.egg.y, img)
end 

fun draw-platform(platform :: Platform, img :: Image) -> Image:
  drawn-platform = rectangle(PLATFORM-WIDTH, PLATFORM-HEIGHT, "solid", PLATFORM-COLOR)
  I.place-image(drawn-platform, platform.x, platform.y, img)
end

fun draw-platforms(state :: State, img :: Image) -> Image:
  state.platforms.foldr(draw-platform(_, _), img)
end

fun draw-score(state :: State, img :: Image) -> Image:
  text-img = text(num-to-string(state.score), 24, "black")
  I.place-image(text-img, SCREEN-WIDTH / 2, (SCREEN-HEIGHT - 130) / 6, img)
end

fun draw-lives(state :: State, img :: Image) -> Image:
  text-img = text("lives: " + num-to-string(state.lives), 18, "black")
  I.place-image(text-img, SCREEN-WIDTH - 40, 20, img)
end

fun draw-game-over(state :: State, img :: Image) -> Image:
  text-img = text("GAME OVER", 50, "RED")
  I.place-image(text-img, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 2, img)
end

fun draw-handler(state :: State) -> Image:
  canvas = empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, 'gray')
  
  cases (GameStatus) state.game-status:
    | ongoing =>
      canvas 
        ^ draw-platforms(state, _) 
        ^ draw-egg(state, _) 
        ^ draw-score(state, _) 
        ^ draw-lives(state, _) 
    | transitioning(_) =>
      canvas 
        ^ draw-platforms(state, _) 
        ^ draw-egg(state, _) 
        ^ draw-score(state, _) 
        ^ draw-lives(state, _) 
    | game-over =>
      canvas 
        ^ draw-platforms(state, _) 
        ^ draw-egg(state, _) 
        ^ draw-score(state, _) 
        ^ draw-lives(state, _) 
        ^ draw-game-over(state, _)
  end
end

### KEYBOARD ###

fun key-handler(state :: State, key :: String) -> State:
  if key == ' ':
    cases (GameStatus) state.game-status:
      | ongoing => 
        if state.egg.is-airborne == false: 
          state.{egg: state.egg.{dy: EGG-JUMP-HEIGHT, ay: 0.8, is-airborne: true}}
        else: state
        end
      | transitioning(_) => state 
      | game-over => INITIAL-STATE 
    end 
  else:
    state
  end
end

### TICKS ###

fun update-y-velocity(state :: State) -> State:
  state.{egg: state.egg.{dy: state.egg.dy + state.egg.ay}}
end

fun update-y-coordinate(state :: State) -> State:
  state.{egg: state.egg.{y: state.egg.y + state.egg.dy}}
end

fun update-y-follow-coordinate(state :: State) -> State: 
  state.{egg: state.egg.{y: state.egg.y + 2.8}}
end

fun bounce(plat :: Platform) -> Number:
  if ((plat.x - (PLATFORM-WIDTH / 2)) <= 0) or ((plat.x + (PLATFORM-WIDTH / 2)) >= SCREEN-WIDTH):
    0 - plat.dx
  else:
    plat.dx
  end
end

fun update-platforms-x-coordinate(state :: State) -> State:
  new-platforms = state.platforms
    .map(lam(platform): platform.{x: platform.x + bounce(platform), dx: bounce(platform)} end)
  
  state.{platforms: new-platforms}
end

fun update-platforms-y-coordinate(state :: State) -> State:
  new-platforms = state.platforms
    .map(lam(platform): platform.{y: (platform.y + 2.8)} end)
    .filter(lam(platform): (platform.y - HALF-PLATFORM-HEIGHT) <= SCREEN-HEIGHT end)
  
  state.{platforms: new-platforms}
end

fun update-ongoing-coordinates(state :: State) -> State:
  state
    ^ update-platforms-x-coordinate(_) 
    ^ update-y-coordinate(_)
end

fun update-transition-coordinates(state :: State) -> State:
  state
    ^ update-y-follow-coordinate(_)
    ^ update-platforms-y-coordinate(_)
end

fun collision-test(state :: State, platform :: Platform) -> Boolean:
  if (state.egg.dy > 0) and ((state.egg.y + EGG-RADIUS) <= platform.y) and ((state.egg.y + EGG-RADIUS) >= (platform.y - HALF-PLATFORM-HEIGHT - 1)) and (state.egg.x <= (platform.x + HALF-PLATFORM-WIDTH)) and (state.egg.x >= (platform.x - HALF-PLATFORM-WIDTH)):
    true
  else: false
  end
end

fun end-game(state :: State, platform :: Platform) -> State:
  state.{egg: state.egg.{x: platform.x, y: (platform.y - HALF-PLATFORM-HEIGHT - EGG-RADIUS)}, lives: state.lives - 1, game-status: game-over}
end

fun lose-hp(state :: State, platform :: Platform) -> State:
  state.{egg: state.egg.{is-airborne: false, dy: 0, ay: 0, x: platform.x, y: (platform.y - HALF-PLATFORM-HEIGHT - EGG-RADIUS)}, lives: state.lives - 1}
end

fun collisions(state :: State) -> State: 
  cases (PlatformLevel) state.current-platform:
    | top => state
    | middle =>
      if collision-test(state, state.platforms.get(2)):
        top-platform = state.platforms.get(2)
        state.{current-platform: top, egg: state.egg.{is-airborne: false, dy: 0, ay: 0, y: (top-platform.y - HALF-PLATFORM-HEIGHT - EGG-RADIUS)}, score: state.score + 1, game-status: (transitioning(100))}
      else if state.egg.y >= SCREEN-HEIGHT:
        if state.lives == 1:
          end-game(state, state.platforms.get(1))
        else:
          lose-hp(state, state.platforms.get(1))
        end
      else: state
      end
    | bottom =>
      if collision-test(state, state.platforms.get(1)):
        middle-platform = state.platforms.get(1)
        state.{current-platform: middle, egg: state.egg.{is-airborne: false, dy: 0, ay: 0, y: (middle-platform.y - HALF-PLATFORM-HEIGHT - EGG-RADIUS)}, score: state.score + 1}
      else if state.egg.y >= SCREEN-HEIGHT:
        if state.lives == 1:
          end-game(state, state.platforms.get(0))
        else:
          lose-hp(state, state.platforms.get(0))
        end
      else: state
      end
  end
end

fun egg-follow-platform(state :: State) -> State:
  if state.egg.is-airborne == false:
    cases (PlatformLevel) state.current-platform:
      | top => 
        top-platform = state.platforms.get(2)
        state.{egg: state.egg.{x: state.egg.x + top-platform.dx}}
      | middle => 
        middle-platform = state.platforms.get(1)
        state.{egg: state.egg.{x: state.egg.x + middle-platform.dx}}
      | bottom =>
        bottom-platform = state.platforms.get(0)
        state.{egg: state.egg.{x: state.egg.x + bottom-platform.dx}}
    end
  else:
    state
  end
end

fun generate-other-platforms(state :: State, ticks :: Number) -> State:
  if (ticks == 100) or (ticks == 50):
    new-platform = [list: {x: (num-random(SCREEN-WIDTH - PLATFORM-WIDTH - PLATFORM-WIDTH) + PLATFORM-WIDTH), y: 0, dx: random-num(5)}]
    
    state.{platforms: state.platforms.append(new-platform)}
  else: state
  end
end

fun update-ticks-left(state :: State, ticks :: Number) -> State:
  state.{game-status: transitioning(ticks - 1)}
end

fun tick-handler(state :: State) -> State:
  cases (GameStatus) state.game-status:
    | ongoing =>
      state
        ^ update-y-velocity(_)
        ^ update-ongoing-coordinates(_)
        ^ egg-follow-platform(_)
        ^ collisions(_)
    | transitioning(ticks-left) => 
      if ticks-left > 0:
        state
          ^ generate-other-platforms(_, ticks-left)
          ^ update-transition-coordinates(_)
          ^ update-ticks-left(_, ticks-left)
      else: 
        state.{game-status: ongoing, current-platform: bottom}
      end 
    | game-over => state
  end
end

### MAIN ###

world = reactor:
  title: 'CS12 21.2 MP (Simple Egg Toss Clone)',
  init: INITIAL-STATE,
  to-draw: draw-handler,
  seconds-per-tick: 1 / 60, # 60 fps
  on-tick: tick-handler,
  on-key: key-handler,
end

R.interact(world)