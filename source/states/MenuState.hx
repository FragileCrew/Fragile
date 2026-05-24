package states;

import haxe.ui.Toolkit;
import haxe.ui.backend.flixel.FlxUIState;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTweenType;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameplay.PlayState;

class MenuState extends FlxUIState {
    var overlay:FlxSprite;
    var titleLabel:Label;
    var playButton:Button;
    var blinkTween:FlxTween;
    var canInteract:Bool = false;

    override function create():Void {
        super.create();

        bgColor = FlxColor.BLACK;
        Toolkit.init();

        buildUI();
        buildOverlay();

        new FlxTimer().start(0.4, _ -> runIntro());
    }

    function buildUI():Void {
        var root = new VBox();
        root.percentWidth    = 100;
        root.percentHeight   = 100;
        root.horizontalAlign = "center";
        root.verticalAlign   = "middle";
        root.customStyle.backgroundColor  = 0x000000;
        root.customStyle.backgroundOpacity = 0;
        root.customStyle.padding          = 0;
        root.customStyle.spacing          = 40;

        titleLabel                     = new Label();
        titleLabel.text                = "FRAGILE";
        titleLabel.horizontalAlign     = "center";
        titleLabel.alpha               = 0;
        titleLabel.customStyle.fontSize   = 72;
        titleLabel.customStyle.color      = 0xFFFFFFFF;
        titleLabel.customStyle.fontBold   = true;
        titleLabel.customStyle.fontName   = "assets/fonts/fragile_title.ttf";

        playButton                        = new Button();
        playButton.text                   = "PLAY";
        playButton.width                  = 200;
        playButton.height                 = 52;
        playButton.horizontalAlign        = "center";
        playButton.alpha                  = 0;
        playButton.disabled               = true;
        playButton.customStyle.fontSize         = 24;
        playButton.customStyle.color            = 0xFFAAAAAA;
        playButton.customStyle.backgroundColor  = 0x00000000;
        playButton.customStyle.backgroundOpacity = 0;
        playButton.customStyle.borderSize       = 1;
        playButton.customStyle.borderColor      = 0xFF3A3A3A;
        playButton.customStyle.fontBold         = true;

        playButton.onClick    = _ -> selectPlay();
        playButton.onMouseOver = _ -> applyHover(true);
        playButton.onMouseOut  = _ -> applyHover(false);

        root.addComponent(titleLabel);
        root.addComponent(playButton);

        Screen.instance.addComponent(root);
    }

    function buildOverlay():Void {
        overlay = new FlxSprite(0, 0);
        overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        overlay.scrollFactor.set(0, 0);
        overlay.alpha = 1.0;
        add(overlay);
    }

    function applyHover(hovered:Bool):Void {
        if (!canInteract)
            return;

        if (blinkTween != null)
            blinkTween.cancel();

        if (hovered) {
            playButton.customStyle.color       = 0xFFFFFFFF;
            playButton.customStyle.borderColor = 0xFF888888;
            playButton.alpha = 1.0;
        } else {
            playButton.customStyle.color       = 0xFFAAAAAA;
            playButton.customStyle.borderColor = 0xFF3A3A3A;
            startBlink();
        }
    }

    function runIntro():Void {
        FlxTween.tween(overlay, { alpha: 0 }, 2.0, {
            ease: FlxEase.quadIn,
            onComplete: _ -> {
                FlxTween.tween(titleLabel, { alpha: 1.0 }, 1.2, {
                    ease: FlxEase.quadOut,
                    onComplete: _ -> {
                        FlxTween.tween(playButton, { alpha: 1.0 }, 0.8, {
                            ease: FlxEase.quadOut,
                            onComplete: _ -> {
                                canInteract        = true;
                                playButton.disabled = false;
                                startBlink();
                            }
                        });
                    }
                });
            }
        });
    }

    function startBlink():Void {
        blinkTween = FlxTween.tween(playButton, { alpha: 0.25 }, 1.0, {
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

        canInteract         = false;
        playButton.disabled = true;

        if (blinkTween != null)
            blinkTween.cancel();

        FlxTween.tween(playButton,  { alpha: 0 }, 0.2, { ease: FlxEase.quadOut });
        FlxTween.tween(titleLabel,  { alpha: 0 }, 0.5, { ease: FlxEase.quadIn });
        FlxTween.tween(overlay, { alpha: 1.0 }, 1.0, {
            ease: FlxEase.quadIn,
            startDelay: 0.3,
            onComplete: _ -> FlxG.switchState(new PlayState())
        });
    }

    override function destroy():Void {
        if (blinkTween != null)
            blinkTween.cancel();
        super.destroy();
    }
}
