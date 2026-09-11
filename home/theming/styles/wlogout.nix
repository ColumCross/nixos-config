{ wlogoutIcons }:
{
  dark = ''
    * { background-image: none; box-shadow: none; }
    window { background-color: rgba(12, 12, 12, 0.9); color: #ffffff; }
    button {
      background-color: #1E1E1E; color: #ffffff; border: 1px solid #33ccff;
      border-radius: 0; margin: 5px; padding: 10px 30px; background-repeat: no-repeat;
      background-position: center; background-size: 25%;
    }
    button:hover, button:focus { background-color: rgba(51, 204, 255, 0.2); box-shadow: 0 0 15px rgba(51, 204, 255, 0.3); color: #33ccff; }
    button:active { background-color: rgba(51, 204, 255, 0.35); color: #33ccff; }
    #lock { background-image: image(url("${wlogoutIcons}/lock.png")); }
    #logout { background-image: image(url("${wlogoutIcons}/logout.png")); }
    #suspend { background-image: image(url("${wlogoutIcons}/suspend.png")); }
    #hibernate { background-image: image(url("${wlogoutIcons}/hibernate.png")); }
    #shutdown { background-image: image(url("${wlogoutIcons}/shutdown.png")); }
    #reboot { background-image: image(url("${wlogoutIcons}/reboot.png")); }
  '';

  light = ''
    * { background-image: none; box-shadow: none; }
    window { background-color: rgba(248, 248, 242, 0.95); color: #282a36; }
    button {
      background-color: #eaecee; color: #282a36; border: 1px solid #0077aa;
      border-radius: 0; margin: 5px; padding: 10px 30px; background-repeat: no-repeat;
      background-position: center; background-size: 25%;
    }
    button:hover, button:focus { background-color: rgba(0, 119, 170, 0.15); box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1); color: #0077aa; }
    button:active { background-color: rgba(0, 119, 170, 0.3); color: #0077aa; }
    #lock { background-image: image(url("${wlogoutIcons}/lock.png")); }
    #logout { background-image: image(url("${wlogoutIcons}/logout.png")); }
    #suspend { background-image: image(url("${wlogoutIcons}/suspend.png")); }
    #hibernate { background-image: image(url("${wlogoutIcons}/hibernate.png")); }
    #shutdown { background-image: image(url("${wlogoutIcons}/shutdown.png")); }
    #reboot { background-image: image(url("${wlogoutIcons}/reboot.png")); }
  '';
}
