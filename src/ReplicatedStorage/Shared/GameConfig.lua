-- Shared configuration values accessible from both server and client.
return {
	GameName = "Arcaneum",

	-- Roblox UserIds allowed to use the admin panel on a published server.
	-- Not needed in Studio testing (AdminService grants access there automatically).
	AdminUserIds = {} :: { number },
}
