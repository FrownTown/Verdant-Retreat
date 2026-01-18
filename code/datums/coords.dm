// Simple coordinate storage datum to avoid circular references
/coords
	parent_type = /datum
	var/x_pos = 0
	var/y_pos = 0
	var/z_pos = 0

/coords/New(x = 0, y = 0, z = 0)
	..()
	x_pos = x
	y_pos = y
	z_pos = z
