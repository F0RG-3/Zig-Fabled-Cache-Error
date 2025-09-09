const std = @import("std");
const ray = @import("raylib");


const HexBoard = struct{

    board : []Hex = undefined,
    number_of_colloumns : u32,
    number_of_rows : u32,
    selected_index : ?usize = null,
    
    const Circle = struct {
        radius : f32,
        pnt : ray.Vector2,
        color : ray.Color = ray.Color.init(100, 100, 150, 255),

        inline fn colliding(self : Circle, nPnt : ray.Vector2) bool {
            return ray.Vector2.distance(self.pnt, nPnt) < self.radius;
        }

        inline fn draw(self : Circle) void {
            ray.drawCircleV(self.pnt, self.radius, self.color);
        }
    };
    
    const Hex = struct {
        pnt : ray.Vector2 = undefined,
        radius : f32 = undefined,

        lineThickness : f32 = 1,
        color : ray.Color = ray.Color.init(255, 200, 80, 255),
        border_color : ray.Color = ray.Color.init(250, 250, 250, 255),

        calcs : ?common_calcs = null,

        const common_calcs = struct {
            pnt : ray.Vector2 = undefined,
            radius : f32 = undefined,
            
            half_side : f32 = undefined,
            shortest_dist_to_side : f32 = undefined,
            



            fn get_common_calcs(self : *Hex) common_calcs {
                //Possible Optimization : it may be faster to just recalculate it and return it then it is
                // to do the if-check
                if (self.calcs == null or self.calcs.?.pnt.x != self.pnt.x or self.calcs.?.pnt.y != self.pnt.y or self.calcs.?.radius != self.radius) {
                    calc_common_calcs(self);
                }
                return self.calcs.?;
            }

            inline fn calc_common_calcs(self : *Hex) void {
                self.calcs = common_calcs{
                    .pnt = self.pnt,
                    .radius = self.radius,
                    .half_side = self.radius/2,
                    .shortest_dist_to_side = @sqrt(3.0)/2.0 * self.radius,
                };
            }
        };

        inline fn draw(self : Hex) void {
            ray.drawPoly(self.pnt, 6, self.radius, 0.0, self.color);
            ray.drawPolyLinesEx(self.pnt, 6, self.radius, 0.0, self.lineThickness, self.border_color);
        }

        inline fn drawEx(self : Hex, lineThickness : f32, c1 : ray.Color, c2 : ray.Color) void {
            ray.drawPoly(self.pnt, 6, self.radius, 0.0, c1);
            ray.drawPolyLinesEx(self.pnt, 6, self.radius, 0.0, lineThickness, c2);
        }

        inline fn _collisionShape(self : *Hex) Circle {
            const shortest_dist = common_calcs.get_common_calcs(self).shortest_dist_to_side;

            if (shortest_dist <= 1) {
                std.debug.print("Error : the radius for the Hexagon-button is {}\n", .{shortest_dist});
                unreachable;
            }

            return Circle{.pnt=self.pnt, .radius=shortest_dist};
        }

        inline fn is_point_inside(self : *Hex, pnt : ray.Vector2) bool {
            //There is a sizeable "dead zone" where technically it is inside the hexagon
            //However it returns false, this is a bufferzone for touchscreen and mouse.

            const circ = self._collisionShape();
            return circ.colliding(pnt);
        }

        inline fn drawCollisionShape(self : *Hex) void {
            const circ = self._collisionShape();
            circ.draw();
        }
    };
    
    const HexDisplay = struct {
        radius : f32 = 30,
        hexColor : ray.Color = ray.Color.init(200, 200, 0, 255),
        borderColor : ray.Color = ray.Color.init(30, 100, 100, 255),
        selectedBorder : ray.Color = ray.Color.init(255, 255, 255, 255),
    };

    inline fn decode(hb : HexBoard, c : usize, r : usize) usize {
        return hb.number_of_rows * c + r;
    }

    fn init(board : []Hex, number_of_colloumns : u32, number_of_rows : u32, radius : f32) HexBoard {
        var tempHex = Hex{
            .pnt = .{.x=0, .y=0},
            .radius = radius
        };
        const startPnt = ray.Vector2.init(0, 0);

        const cc = Hex.common_calcs.get_common_calcs(&tempHex);
        var hb = HexBoard{
            .board = board, 
            .number_of_colloumns = number_of_colloumns,
            .number_of_rows = number_of_rows,
        };

        for (0..number_of_colloumns) |c| {

            const cEven : f32 = @floatFromInt(c % 2);
            for (0..number_of_rows) |r| {


                const hexX = 1.5 * radius * @as(f32, @floatFromInt(c)) + startPnt.x;
                const R_f32 : f32 = @floatFromInt(r);
                const hexY = startPnt.y + (cc.shortest_dist_to_side * cEven) + (cc.shortest_dist_to_side * R_f32 * 2);

                const hexPoint = ray.Vector2.init(hexX, hexY);



                //std.debug.print("r : {}, Even : {d}, X : {d:.3}, Y : {d:.3}\n", .{r, cEven, hexX, hexY});

                board[hb.decode(c, r)] = Hex{.pnt = hexPoint, .radius=radius};
            }
        }

        return hb;
    }

    fn initWidthHeight(board : []Hex, start_point : ray.Vector2, number_of_colloumns : u32, number_of_rows : u32, width : u32, height : u32) HexBoard {
        


        const height_f32 : f32 = @floatFromInt(height);
        const width_f32 : f32 = @floatFromInt(width);
        const noc_f32 : f32 = @floatFromInt(number_of_colloumns);
        const nor_f32 : f32 = @floatFromInt(number_of_rows);


        const maxRadiusFromHeight : f32 = blk : {
            if (number_of_colloumns == 0) unreachable;
            if (number_of_colloumns == 1) {
                break :blk (height_f32 / (nor_f32 * @sqrt(3.0)));
            }
            break :blk (2 * height_f32 / ((2 * nor_f32 + 1) * @sqrt(3.0)) );
        };

        const maxRadiusFromWidth : f32 = (2 * width_f32) / (3.0 * noc_f32 + 1);
        const radius = @min(maxRadiusFromHeight, maxRadiusFromWidth);




        var tempHex = Hex{
            .pnt = start_point,
            .radius = radius
        };
        

        const cc = Hex.common_calcs.get_common_calcs(&tempHex);

        const startX : f32 = radius + (noc_f32 * (maxRadiusFromWidth - radius) / 2);
        const startY : f32 = cc.shortest_dist_to_side + (nor_f32*(maxRadiusFromHeight - radius) / 2);

        const startPnt = ray.Vector2.init(startX, startY);

        var hb = HexBoard{
            .board = board, 
            .number_of_colloumns = number_of_colloumns,
            .number_of_rows = number_of_rows,
        };

        for (0..number_of_colloumns) |c| {

            const cEven : f32 = @floatFromInt(c % 2);
            for (0..number_of_rows) |r| {


                const hexX = 1.5 * radius * @as(f32, @floatFromInt(c)) + startPnt.x;
                const R_f32 : f32 = @floatFromInt(r);
                const hexY = startPnt.y + (cc.shortest_dist_to_side * cEven) + (cc.shortest_dist_to_side * R_f32 * 2);

                const hexPoint = ray.Vector2.init(hexX, hexY);



                //std.debug.print("r : {}, Even : {d}, X : {d:.3}, Y : {d:.3}\n", .{r, cEven, hexX, hexY});

                board[hb.decode(c, r)] = Hex{.pnt = hexPoint, .radius=radius};
            }
        }

        return hb;

    }

    pub fn displayBoard(hb : HexBoard) void {
        for (hb.board, 0..) |hex, i| {
            if (i == hb.selected_index) {
                hex.drawEx(hex.lineThickness, ray.Color.init(255, 0, 0, 255), ray.Color.init(0, 255, 0, 255));
            } else {
                hex.draw(); 
            }
        }
    }

    pub fn displayCollisionShapes(hb : *HexBoard) void {
        for (hb.board) |*hex| {
            Hex.drawCollisionShape(hex);
        }
    }

    pub fn isPointColliding(hb : *HexBoard, pnt : ray.Vector2) ?usize {
        //This code is inefficient (it just loops through every point) and may need to be replaced.

        for (hb.board, 0..) |*hex, i| {
            if (hex.is_point_inside(pnt)) {
                return i;
            }
        }
        return null;
    }

    pub fn maximumRadiusOfHex(self : HexBoard, width : u32, height : u32) f32 {
        //Casting NONESENSE :
        const width_fit = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(self.number_of_colloumns));
        const height_fit = @as(f32, @floatFromInt(height)) / @as(f32, @floatFromInt(self.number_of_rows));

        std.debug.print("BTW your math for calculating the maximumRadiusOfHex is wrong.\n", .{});

        return @min(width_fit, height_fit);
    }

};


pub fn main() !void {

    ray.setTraceLogLevel(.none);

    const width = 1000;
    const height = 600;
    var brd : [20]HexBoard.Hex = undefined;

    //var hexBoard = HexBoard.init(&brd, 5, 4, 20);
    var hexBoard = HexBoard.initWidthHeight(&brd, ray.Vector2.init(0, 0), 5, 4, width, height);

    ray.initWindow(width, height, "Hello, World!");
    defer ray.closeWindow();

    ray.setTargetFPS(60);

    while (!ray.windowShouldClose()) {

        if (ray.isMouseButtonPressed(.left)) {
            const res = hexBoard.isPointColliding(ray.getMousePosition());

            if (res != null) {
                hexBoard.selected_index = res;
            }
        }

        ray.beginDrawing();
        defer ray.endDrawing();

        ray.clearBackground(ray.Color.init(10, 10, 0, 255));
        hexBoard.displayBoard();
        hexBoard.displayCollisionShapes();
    }
}
