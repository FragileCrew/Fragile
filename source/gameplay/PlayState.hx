package gameplay;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import entities.Player;
import entities.Enemy;
import entities.NPC;
import objects.Door;
import objects.Chest;
import ui.HUD;
import ui.DialogBox;

class PlayState extends FlxState {
    public static var instance(default, null):PlayState;

    var player:Player;
    var hud:HUD;
    var dialog:DialogBox;

    var map:FlxTilemap;
    var wallsMap:FlxTilemap;

    var enemies:FlxGroup;
    var npcs:FlxGroup;
    var doors:FlxGroup;
    var chests:FlxGroup;

    var camGame:FlxCamera;
    var camHUD:FlxCamera;

    var currentRoom:String;
    var transitioning:Bool = false;

    var ambience:FlxSound;

    public function new(room:String = "room_01"):Void {
        super();
        currentRoom = room;
    }

    override function create():Void {
        super.create();

        instance = this;

        setupCameras();
        loadRoom(currentRoom);
        setupHUD();
        setupAmbience();
        fadeIn();
    }

    function setupCameras():Void {
        camGame = new FlxCamera();
        camGame.bgColor = FlxColor.BLACK;

        camHUD = new FlxCamera();
        camHUD.bgColor = FlxColor.TRANSPARENT;

        FlxG.cameras.reset(camGame);
        FlxG.cameras.add(camHUD, false);
    }

    function loadRoom(room:String):Void {
        currentRoom = room;

        enemies = new FlxGroup();
        npcs    = new FlxGroup();
        doors   = new FlxGroup();
        chests  = new FlxGroup();

        map = new FlxTilemap();
        map.loadMapFromCSV(
            'assets/maps/${room}_floor.csv',
            'assets/images/tiles/tileset.png',
            16, 16,
            FlxTilemapAutoTiling.OFF
        );

        wallsMap = new FlxTilemap();
        wallsMap.loadMapFromCSV(
            'assets/maps/${room}_walls.csv',
            'assets/images/tiles/tileset.png',
            16, 16,
            FlxTilemapAutoTiling.OFF
        );

        add(map);
        add(wallsMap);
        add(chests);
        add(doors);
        add(npcs);
        add(enemies);

        spawnEntities(room);

        if (player == null) {
            player = new Player(80, 80);
        } else {
            player.setPosition(80, 80);
        }

        add(player);

        camGame.follow(player, FlxCameraFollowStyle.TOPDOWN_TIGHT, 0.08);
        camGame.setScrollBoundsRect(0, 0, map.width, map.height, true);
    }

    function spawnEntities(room:String):Void {
        switch (room) {
            case "room_01":
                var door = new Door(240, 32, "room_02");
                doors.add(door);
            case "room_02":
                var enemy = new Enemy(160, 160);
                enemies.add(enemy);
                var npc = new NPC(80, 200, "Não vá lá dentro...");
                npcs.add(npc);
            default:
        }
    }

    function setupHUD():Void {
        hud    = new HUD(player);
        dialog = new DialogBox();

        hud.camera    = camHUD;
        dialog.camera = camHUD;

        add(hud);
        add(dialog);
    }

    function setupAmbience():Void {
        ambience = FlxG.sound.load('assets/music/ambience_${currentRoom}.ogg', 0.4, true);
        ambience.play();
    }

    function fadeIn():Void {
        var overlay = new FlxSprite(0, 0);
        overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        overlay.scrollFactor.set(0, 0);
        overlay.cameras = [camHUD];
        add(overlay);

        FlxTween.tween(overlay, { alpha: 0 }, 1.2, {
            ease: FlxEase.quadOut,
            onComplete: _ -> remove(overlay)
        });
    }

    public function startTransition(targetRoom:String):Void {
        if (transitioning)
            return;

        transitioning = true;

        if (ambience != null)
            FlxTween.tween(ambience, { volume: 0 }, 0.8, {
                onComplete: _ -> ambience.stop()
            });

        var overlay = new FlxSprite(0, 0);
        overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        overlay.scrollFactor.set(0, 0);
        overlay.alpha = 0;
        overlay.cameras = [camHUD];
        add(overlay);

        FlxTween.tween(overlay, { alpha: 1.0 }, 0.9, {
            ease: FlxEase.quadIn,
            onComplete: _ -> {
                FlxG.switchState(new PlayState(targetRoom));
            }
        });
    }

    public function showDialog(text:String, ?onClose:Void -> Void):Void {
        player.freeze();
        dialog.show(text, () -> {
            player.unfreeze();
            if (onClose != null)
                onClose();
        });
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (transitioning)
            return;

        FlxG.collide(player, wallsMap);
        FlxG.collide(enemies, wallsMap);

        FlxG.overlap(player, doors, (_, door) -> {
            var d = cast(door, Door);
            startTransition(d.targetRoom);
        });

        FlxG.overlap(player, npcs, (_, npc) -> {
            var n = cast(npc, NPC);
            if (FlxG.keys.justPressed.E && !dialog.visible)
                showDialog(n.message);
            #if mobile
            if (FlxG.touches.getFirst() != null && !dialog.visible)
                showDialog(n.message);
            #end
        });

        FlxG.overlap(player, enemies, (_, enemy) -> {
            var e = cast(enemy, Enemy);
            player.takeDamage(e.contactDamage);
        });

        #if desktop
        if (FlxG.keys.justPressed.F)
            Fragile.toggleFullscreen();

        if (FlxG.keys.justPressed.ESCAPE)
            FlxG.switchState(new states.MenuState());
        #end

        hud.update(elapsed);
    }

    override function destroy():Void {
        instance = null;
        if (ambience != null) {
            ambience.stop();
            ambience.destroy();
        }
        super.destroy();
    }
}
