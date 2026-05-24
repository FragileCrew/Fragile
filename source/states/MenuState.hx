package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class MenuState extends FlxState {
    var title:FlxText;
    var playOption:FlxText;
    var overlay:FlxSprite;
    var canInteract:Bool = false;

    override function create():Void {
        super.create();

        bgColor = FlxColor.BLACK;

        overlay = new FlxSprite(0, 0);
        overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        overlay.alpha = 1.0;
        overlay.scrollFactor.set(0, 0);

        title = new FlxText(0, 0, FlxG.width, "FRAGILE");
        title.setFormat(null, 72, FlxColor.WHITE, CENTER);
        title.y = (FlxG.height / 2) - 100;
        title.alpha = 0;
        title.scrollFactor.set(0, 0);

        playOption = new FlxText(0, 0, FlxG.width, "PLAY");
        playOption.setFormat(null, 28, 0xFFAAAAAA, CENTER);
        playOption.y = (FlxG.height / 2) + 20;
        playOption.alpha = 0;
        playOption.scrollFactor.set(0, 0);

        add(title);
        add(playOption);
        add(overlay);

        new FlxTimer().start(0.4, _ -> runIntro());
    }

    function runIntro():Void {
        FlxTween.tween(overlay, { alpha: 0 }, 2.0, {
            ease: FlxEase.quadIn,
            onComplete: _ -> {
                FlxTween.tween(title, { alpha: 1.0 }, 1.2, {
                    ease: FlxEase.quadOut,
                    onComplete: _ -> {
                        FlxTween.tween(playOption, { alpha: 1.0 }, 0.8, {
                            ease: FlxEase.quadOut,
                            onComplete: _ -> {
                                canInteract = true;
                                startBlink();
                            }
                        });
                    }
                });
            }
        });
    }

    function startBlink():Void {
        FlxTween.tween(playOption, { alpha: 0.2 }, 0.9, {
            ease: FlxEase.sineInOut,
            type: FlxTweenType.PINGPONG
        });
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (!canInteract)
            return;

        #if mobile
        if (FlxG.touches.getFirst() != null)
            selectPlay();
        #else
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
            selectPlay();
        #end
    }

    function selectPlay():Void {
        if (!canInteract)
            return;

        canInteract = false;

        FlxTween.tween(playOption, { alpha: 0 }, 0.2, { ease: FlxEase.quadOut });
        FlxTween.tween(title, { alpha: 0 }, 0.4, {
            ease: FlxEase.quadIn,
            onComplete: _ -> {
                FlxTween.tween(overlay, { alpha: 1.0 }, 1.0, {
                    ease: FlxEase.quadIn,
                    onComplete: _ -> FlxG.switchState(new PlayState())
                });
            }
        });
    }
}
