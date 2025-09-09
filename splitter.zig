const std = @import("std");
const fs = std.fs;

const print = std.debug.print;

pub fn edit_file_name(allocator : std.mem.Allocator, start_str : [:0] const u8, name_suffix : [] const u8, end_signifier : []const u8) ![] u8 {
    const dot_index = blk : {
        for (0..start_str.len) |i| {
            const n = start_str.len - (i + 1); // search from the end

            if (start_str[n] == '.') break : blk n;
        }
        unreachable;
    };

    const new_str = try allocator.alloc(u8, start_str.len + name_suffix.len + end_signifier.len);


    // print("Str Transform :\n", .{});
    for (0..dot_index) |i| {
        new_str[i] = start_str[i];
    }

    // print("A: <{s}> => ", .{new_str});
    for (0..name_suffix.len) |i| {
        const adj_i = i + dot_index;
        new_str[adj_i] = name_suffix[i];
    }

    // print("B: <{s}> |{s}, {}|\n", .{new_str, end_signifier, end_signifier.len});
    for (0..end_signifier.len) |i| {
        const adj_i = i + dot_index + name_suffix.len;
        new_str[adj_i] = end_signifier[i];
    }

    // print("C: <{s}> => ", .{new_str});
    for (0..(start_str.len - dot_index)) |i| {
        const adj_i = i + dot_index + name_suffix.len + end_signifier.len;
        const adj_2 = i + dot_index;

        new_str[adj_i] = start_str[adj_2];
    }

    // print("Final : <{s}>\n\n", .{new_str});
    return new_str;
}

pub fn main() !void {

    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if ( ! (args.len == 2 or args.len == 3) ) unreachable;
    var max_size_in_bytes : usize = 25_000_000; // The program will split on intervals of 25 Megabytes by default


    if (args.len == 3) {
        max_size_in_bytes = try std.fmt.parseInt(usize, args[2], 10);
    } else if (args.len != 2) {
        unreachable;
    }

    const cwd = fs.cwd();
    const file = try cwd.openFileZ(args[1], .{.mode=.read_only});
    defer file.close();
    const file_stats = try file.stat();
    const file_size = file_stats.size;



    if (max_size_in_bytes > file_size) {
        print("The file is smaller than the provided threshold. The file needs no change\n", .{});
        return;
    }


    

    const data = try allocator.alloc(u8, file_size);
    defer allocator.free(data);

    var data_reader = file.reader(data);
    try data_reader.interface.fill(file_size);


    const f32_fs : f32 = @floatFromInt(file_size);
    const f32_msib : f32 = @floatFromInt(max_size_in_bytes);

    const needed_parts : u32 = @min(10, @as(u32, @intFromFloat( @ceil(f32_fs / f32_msib) )));
    const write_buffer = try allocator.alloc(u8, max_size_in_bytes);


    if (file_size != data.len) unreachable;
    print("The Provided File is : <{}> Bytes Large\n", .{file_size});


    print("The command you will need to run to rejoin them:\n", .{});
    const returned_name = try edit_file_name(allocator, args[1], "_reformed", "");
    print("./rejoiner {s}", .{returned_name});
    allocator.free(returned_name);

    for (0..needed_parts) |i| {
        const str_num = try std.fmt.allocPrint(allocator, "{}", .{i});
        const new_name = try edit_file_name(allocator, args[1], "__split_", str_num);

        print(" {s}", .{new_name});
        
        const new_file = try cwd.createFileZ(@ptrCast(new_name), .{.exclusive = true});
        var file_writer = new_file.writer(write_buffer);

        const start_index = i * max_size_in_bytes;
        const end_index = @min((i + 1) * max_size_in_bytes, data.len);

        try file_writer.interface.writeAll(data[start_index .. end_index]);
        try file_writer.interface.flush();

        allocator.free(str_num);
        new_file.close();
    }

    print("\n", .{});
    
}