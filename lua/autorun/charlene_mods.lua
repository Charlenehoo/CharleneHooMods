if SERVER then
    include("charlene_mods/player_create_prop_ragdoll/init.lua")
    include("charlene_mods/first_person_body_blood_decal/init.lua")
else
    include("charlene_mods/first_person_body_blood_decal/cl_init.lua")
end
