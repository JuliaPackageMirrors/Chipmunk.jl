# SFML.jl is required to use debug drawing

import SFML

# Color is from 0.0 to 1.0
type DebugColor
	r::Cfloat
	g::Cfloat
	b::Cfloat
	a::Cfloat
end

type DebugDrawOptions
	draw_circle::Ptr{Void}
	draw_segment::Ptr{Void}
	draw_fatsegment::Ptr{Void}
	draw_polygon::Ptr{Void}
	draw_dot::Ptr{Void}

	flags::Cint
	shape_outlinecolor::DebugColor
	color_for_shape::Ptr{Void}
	constraint_color::DebugColor
	collision_point_color::DebugColor

	data::Ptr{Void}
end

function debug_draw_circle(pos::Vect, angle::Cdouble, radius::Cdouble, outlinecolor::DebugColor, fillcolor::DebugColor, data::Ptr{Void})
	circle = SFML.CircleShape()
	SFML.set_radius(circle, radius)
	SFML.set_position(circle, SFML.Vector2f(pos.x, pos.y))
	SFML.set_rotation(circle, -rad2deg(angle))
	SFML.set_outlinecolor(circle, SFML.Color(outlinecolor.r * 255, outlinecolor.g * 255, outlinecolor.b * 255, outlinecolor.a * 255))
	SFML.set_fillcolor(circle, SFML.Color(fillcolor.r * 255, fillcolor.g * 255, fillcolor.b * 255, fillcolor.a * 255))

	window = SFML.RenderWindow(data)
	SFML.draw(window, circle)
	return nothing
end

function debug_draw_segment(a::Vect, b::Vect, color::DebugColor, data::Ptr{Void})
	line = SFML.Line(SFML.Vector2f(a.x, a.y), SFML.Vector2f(b.x, b.y), 1)
	SFML.set_fillcolor(line, SFML.Color(color.r * 255, color.g * 255, color.b * 255, color.a * 255))

	window = SFML.RenderWindow(data)
	SFML.draw(window, line)
	return nothing
end

function debug_draw_fatsegment(a::Vect, b::Vect, radius::Cdouble, outlinecolor::DebugColor, fillcolor::DebugColor, data::Ptr{Void})
	line = SFML.Line(SFML.Vector2f(a.x, a.y), SFML.Vector2f(b.x, b.y), 2*radius)
	SFML.set_outlinecolor(line, SFML.Color(outlinecolor.r * 255, outlinecolor.g * 255, outlinecolor.b * 255, outlinecolor.a * 255))
	SFML.set_fillcolor(line, SFML.Color(fillcolor.r * 255, fillcolor.g * 255, fillcolor.b * 255, fillcolor.a * 255))

	window = SFML.RenderWindow(data)
	SFML.draw(window, line)
	return nothing
end

function debug_draw_dot(size::Cdouble, pos::Vect, color::DebugColor, data::Ptr{Void})
	dot = SFML.CircleShape()
	SFML.set_radius(dot, size)
	SFML.set_position(dot, SFML.Vector2f(pos.x, pos.y))
	SFML.set_fillcolor(dot, SFML.Color(color.r * 255, color.g * 255, color.b * 255, color.a * 255))

	window = SFML.RenderWindow(data)
	SFML.draw(window, dot)
	return nothing
end

function color_for_shape(shape_ptr::Ptr{Void}, data::Ptr{Void})
	println("Color for shape")
	shape = Shape(shape_ptr)

	if is_sleeping(shape)
		# Draw in gray
		return DebugColor(0.4, 0.4, 0.4, 1.0)
	else
		# Draw in red
		return DebugColor(0.8, 0.0, 0.0, 1.0)
	end
end

function DebugDrawOptions(window)
	c_draw_circle = cfunction(debug_draw_circle, Void, (Vect, Cdouble, Cdouble, DebugColor, DebugColor, Ptr{Void}))
	c_draw_segment = cfunction(debug_draw_segment, Void, (Vect, Vect, DebugColor, Ptr{Void}))
	c_draw_fatsegment = cfunction(debug_draw_fatsegment, Void, (Vect, Vect, Cdouble, DebugColor, DebugColor, Ptr{Void}))
	c_draw_polygon = C_NULL
	c_draw_dot = cfunction(debug_draw_dot, Void, (Cdouble, Vect, DebugColor, Ptr{Void}))
	c_color_for_shape = cfunction(color_for_shape, DebugColor, (Ptr{Void}, Ptr{Void}))
	println("Color for shape: $(c_color_for_shape)")

	options = DebugDrawOptions(c_draw_circle,
				     c_draw_segment,
					 c_draw_fatsegment,
					 c_draw_polygon,
					 c_draw_dot,
					 1<<0,
					 DebugColor(0.0, 0.0, 1.0, 1.0),
					 c_color_for_shape,
					 DebugColor(0.0, 1.0, 0.0, 1.0),
					 DebugColor(1.0, 1.0, 0.0, 1.0),
					 window.ptr)
	
	println(sizeof(options))
	options
end

function debug_draw(space::Space, window::SFML.RenderWindow; clear_and_display=false)
	event = SFML.Event()
	SFML.pollevent(window, event)
	options = DebugDrawOptions(window)
	println("Window: $(window.ptr)")

	if clear_and_display
		SFML.clear(window, SFML.white)
	end
	
	ccall(dlsym(libchipmunk, :cpSpaceDebugDraw), Void, (Ptr{Void}, Ptr{DebugDrawOptions},), space.ptr, pointer_from_objref(options))

	if clear_and_display
		SFML.display(window)
	end
end

export debug_draw