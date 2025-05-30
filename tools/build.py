import installer_builder as ib
import packer as p
import os


if __name__ == "__main__":
    ib.save_lua_file()
    p.save_lua_file()
    os.system("luamin -f ccmaze.lua > ccmaze-min.lua")