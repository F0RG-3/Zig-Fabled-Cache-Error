const std = @import("std");
const fs = std.fs;

const print = std.debug.print;

pub fn get_prior(index : usize, prior_sizes : []usize) usize {
    var final_num : usize = 0;
    for (prior_sizes[0..index]) |num| {
        final_num += num;
    }
    return final_num;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const final_file_name = args[1];
    const files_to_rejoin = args[2..];

    const file_sizes = try allocator.alloc(usize, files_to_rejoin.len);
    defer allocator.free(file_sizes);

    if (files_to_rejoin.len == 1) unreachable;

    const cwd = fs.cwd();


    const final_file_size = blk : {
        var final_size : usize = 0;

        for (files_to_rejoin, 0..) |file_name, i| {
            const file = try cwd.openFileZ(file_name, .{.mode = .read_only});
            const stat = try file.stat();

            file_sizes[i] = stat.size;
            final_size += stat.size;
            file.close();
        }

        break : blk final_size;
    };


    const final_data = try allocator.alloc(u8, final_file_size);
    defer allocator.free(final_data);

    for (files_to_rejoin, 0..) |file_name, i| {
        const start_location = get_prior(i, file_sizes);
        const end_location = file_sizes[i] + start_location;

        const file = try cwd.openFileZ(file_name, .{.mode = .read_only});
        
        var __reader = file.reader(final_data[start_location..end_location]);
        try __reader.interface.fill(file_sizes[i]);
        file.close();
    }


    
    const final_file = try cwd.createFileZ(final_file_name, .{.exclusive = true});
    var __writer = final_file.writer(final_data);
    var interface = &__writer.interface;


    interface.end = final_data.len;
    try interface.flush();
    final_file.close();

    print("The File has been regenerated. It is <{}> Bytes Large.", .{final_data.len});
}