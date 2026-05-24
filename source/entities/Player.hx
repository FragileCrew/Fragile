package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class Player extends FlxSprite {
    static inline final SPEED:Float          = 110.0;
    static inline final SPRINT_SPEED:Float   = 185.0;
    static inline final DRAG:Float           = 900.0;
    static inline final MAX_HP:Int           = 100;
    static inline final IFRAME_TIME:Float    = 1.2;
    static inline final FOOTSTEP_DELAY:Float = 0.38;

    public var hp(default, null):Int           = MAX_HP;
    public var maxHp(default, null):Int        = MAX_HP;
    public var alive(default, null):Bool       = true;
    public var frozen(default, null):Bool      = false;
    public var isSprinting(default, null):Bool = false;

    public var onDeath:Void -> Void;
    public var onHurt:Int -> Void;

    var iframes:Bool = false;
    var iframeTimer:FlxTimer;
    var footstepTimer:FlxTimer;
    var hurtTween:FlxTween;

    var lastDir:FlxPoint = new FlxPoint(0, 1);

    var sfxHurt:FlxSound;
    var sfxFootstep:FlxSound;
    var sfxDeath:FlxSound;

    public function new(x:Float, y:Float) {
        super(x, y);

        loadGraphic("assets/images/player/player_sheet.png", true, 16, 16);
        setupAnimations();
        setupPhysics();
        setupSounds();

        iframeTimer   = new FlxTimer();
        footstepTimer = new FlxTimer();
    }

    function setupAnimations():Void {
        animation.add("idle_down",  [0],            6,  true);
        animation.add("idle_up",    [4],            6,  true);
        animation.add("idle_side",  [8],            6,  true);
        animation.add("walk_down",  [0,  1,  2,  3],  8,  true);
        animation.add("walk_up",    [4,  5,  6,  7],  8,  true);
        animation.add("walk_side",  [8,  9, 10, 11],  8,  true);
        animation.add("hurt",       [12, 13],       10, false);
        animation.add("death",      [14, 15, 16, 17], 6, false);
        animation.play("idle_down");
    }

    function setupPhysics():Void {
        drag.set(DRAG, DRAG);
        maxVelocity.set(SPRINT_SPEED, SPRINT_SPEED);
        setSize(10, 8);
        offset.set(3, 8);
    }

    function setupSounds():Void {
        sfxHurt     = FlxG.sound.load("assets/sounds/player_hurt.ogg",     0.8);
        sfxFootstep = FlxG.sound.load("assets/sounds/player_footstep.ogg", 0.4);
        sfxDeath    = FlxG.sound.load("assets/sounds/player_death.ogg",    1.0);
    }

    override function update(elapsed:Float):Void {
        if (!alive || frozen) {
            velocity.set(0, 0);
            super.update(elapsed);
            return;
        }

        handleMovement();
        handleAnimations();
        handleIframes();

        super.update(elapsed);
    }

    function handleMovement():Void {
        var moveX:Float = 0;
        var moveY:Float = 0;

        #if mobile
        var touch = FlxG.touches.getFirst();
        if (touch != null) {
            var dx  = touch.x - getMidpoint().x;
            var dy  = touch.y - getMidpoint().y;
            var len = Math.sqrt(dx * dx + dy * dy);
            if (len > 12) {
                moveX = dx / len;
                moveY = dy / len;
            }
        }
        #else
        if (FlxG.keys.pressed.LEFT  || FlxG.keys.pressed.A) moveX -= 1;
        if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) moveX += 1;
        if (FlxG.keys.pressed.UP    || FlxG.keys.pressed.W) moveY -= 1;
        if (FlxG.keys.pressed.DOWN  || FlxG.keys.pressed.S) moveY += 1;
        isSprinting = FlxG.keys.pressed.SHIFT;
        #end

        if (moveX != 0 || moveY != 0) {
            var len = Math.sqrt(moveX * moveX + moveY * moveY);
            moveX /= len;
            moveY /= len;
            lastDir.set(moveX, moveY);
        }

        var spd = isSprinting ? SPRINT_SPEED : SPEED;
        velocity.set(moveX * spd, moveY * spd);
    }

    function handleAnimations():Void {
        var moving = velocity.x != 0 || velocity.y != 0;

        if (animation.curAnim != null) {
            if (animation.curAnim.name == "hurt" && !animation.curAnim.finished) return;
            if (animation.curAnim.name == "death") return;
        }

        var absX = Math.abs(lastDir.x);
        var absY = Math.abs(lastDir.y);

        if (moving) {
            if (absX > absY) {
                flipX = lastDir.x < 0;
                animation.play("walk_side", false);
            } else if (lastDir.y < 0) {
                animation.play("walk_up",   false);
            } else {
                animation.play("walk_down", false);
            }

            if (!footstepTimer.active)
                footstepTimer.start(isSprinting ? FOOTSTEP_DELAY * 0.6 : FOOTSTEP_DELAY, _ -> {
                    if (velocity.x != 0 || velocity.y != 0)
                        sfxFootstep.play(true);
                }, 0);
        } else {
            footstepTimer.cancel();

            if (absX > absY)
                animation.play("idle_side", false);
            else if (lastDir.y < 0)
                animation.play("idle_up",   false);
            else
                animation.play("idle_down", false);
        }
    }

    function handleIframes():Void {
        if (iframes)
            alpha = (Math.floor(FlxG.game.ticks / 80) % 2 == 0) ? 0.3 : 1.0;
        else
            alpha = 1.0;
    }

    public function takeDamage(amount:Int):Void {
        if (!alive || iframes || frozen)
            return;

        hp = clampInt(hp - amount, 0, maxHp);

        if (onHurt != null)
            onHurt(hp);

        sfxHurt.play(true);

        if (hp <= 0) {
            die();
            return;
        }

        animation.play("hurt", true);

        if (hurtTween != null)
            hurtTween.cancel();

        color = FlxColor.RED;
        hurtTween = FlxTween.tween(this, { "color": FlxColor.WHITE }, 0.3, {
            ease: FlxEase.quadOut
        });

        iframes = true;
        iframeTimer.start(IFRAME_TIME, _ -> {
            iframes = false;
            alpha   = 1.0;
        });
    }

    public function heal(amount:Int):Void {
        if (!alive)
            return;

        hp = clampInt(hp + amount, 0, maxHp);

        if (onHurt != null)
            onHurt(hp);
    }

    function die():Void {
        alive   = false;
        iframes = false;
        alpha   = 1.0;
        velocity.set(0, 0);

        sfxDeath.play(true);
        animation.play("death", true);

        new FlxTimer().start(1.8, _ -> {
            if (onDeath != null)
                onDeath();
        });
    }

    public function freeze():Void {
        frozen = true;
        velocity.set(0, 0);
        footstepTimer.cancel();
    }

    public function unfreeze():Void {
        frozen = false;
    }

    public function respawn(x:Float, y:Float):Void {
        setPosition(x, y);
        hp      = maxHp;
        alive   = true;
        frozen  = false;
        iframes = false;
        alpha   = 1.0;
        color   = FlxColor.WHITE;
        animation.play("idle_down");
    }

    public function getHpPercent():Float {
        return hp / maxHp;
    }

    static inline function clampInt(v:Int, min:Int, max:Int):Int {
        return v < min ? min : v > max ? max : v;
    }

    override function destroy():Void {
        iframeTimer.cancel();
        footstepTimer.cancel();
        if (hurtTween != null)
            hurtTween.cancel();
        lastDir.put();
        super.destroy();
    }
}
