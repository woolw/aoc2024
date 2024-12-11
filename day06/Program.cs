using types;

string content = File.ReadAllText("input");

var input = content.Split('\n')
    .Where(x => x.Length > 1)
    .Select(x => x.ToCharArray().ToList())
    .ToList();

var (pos, delta) = init_vec(input);

var (g_map, _) = check_bound(pos, delta, input);
int p1 = g_map.Select(y => y.Where(x => x == '|' || x == '-' || x == '+').Count()).Sum();
print_map(g_map);

Console.WriteLine($"Part One: {p1}");
int p2 = 0;
for (int y = 0; y < g_map.Count; y++)
{
    for (int x = 0; x < g_map[y].Count; x++)
    {
        if (g_map[y][x] == '.' || g_map[y][x] == '#')
            continue;

        // Console.WriteLine($"Iterations left: {p1--}");

        input = content.Split('\n')
            .Where(x => x.Length > 1)
            .Select(x => x.ToCharArray().ToList())
            .ToList();
        (pos, delta) = init_vec(input);
        if (pos.Equals(new Vec2(x, y)))
            continue;

        input[y][x] = '0';
        Dictionary<string, int> s_pos = [];
        var init = new Vec2(x, y);
        s_pos.Add(init.ToString(), 0);
        var (s_map, _, c) = check_stuck(pos, delta, input, s_pos);
        //print_map(s_map);
        if (c.All(cc => cc.Value < 4))
            continue;

        p2 += 1;
        print_map(s_map);
        // Console.WriteLine($"Current p2: {p2}");
    }
}

Console.WriteLine($"Part Two: {p2}");

return;

static (List<List<char>>, Vec2?) check_bound(Vec2 pos, Vec2 delta, List<List<char>> g_map)
{
    var n_pos = new Vec2(pos.X + delta.X, pos.Y + delta.Y);

    if (n_pos.X < 0 || n_pos.Y < 0 || n_pos.X >= g_map[pos.Y].Count || n_pos.Y >= g_map.Count)
    {
        g_map[pos.Y][pos.X] = delta.GetDirectionChar(g_map[pos.Y][pos.X]);
        return (g_map, null);
    }

    if (g_map[n_pos.Y][n_pos.X] != '#')
    {
        g_map[n_pos.Y][n_pos.X] = delta.GetDirectionChar(g_map[n_pos.Y][n_pos.X]);

        (g_map, pos) = check_bound(n_pos, delta, g_map);
        if (pos is null)
            return (g_map, null);
    }

    delta.Rotate();
    g_map[pos.Y][pos.X] = '+';

    (g_map, n_pos) = check_bound(pos, delta, g_map);
    if (n_pos is null)
        return (g_map, null);

    return (g_map, n_pos);
}

static (List<List<char>>, Vec2?, Dictionary<string, int>) check_stuck(Vec2 pos, Vec2 delta, List<List<char>> g_map, Dictionary<string, int> s_pos)
{
    var n_pos = new Vec2(pos.X + delta.X, pos.Y + delta.Y);
    while (n_pos.X >= 0
        && n_pos.Y >= 0
        && n_pos.X < g_map[pos.Y].Count
        && n_pos.Y < g_map.Count
        && s_pos.All(x => x.Value < 4))
    {
        while (g_map[n_pos.Y][n_pos.X] != '#' && g_map[n_pos.Y][n_pos.X] != '0')
        {
            g_map[n_pos.Y][n_pos.X] = delta.GetDirectionChar(g_map[n_pos.Y][n_pos.X]);

            pos = n_pos;

            n_pos = new Vec2(n_pos.X + delta.X, n_pos.Y + delta.Y);
            if (s_pos.TryGetValue(n_pos.ToString(), out var _))
                s_pos[n_pos.ToString()] += 1;

            if (n_pos.X < 0
                || n_pos.Y < 0
                || n_pos.X >= g_map[pos.Y].Count
                || n_pos.Y >= g_map.Count
                || s_pos.Any(x => x.Value >= 4))
            {
                return (g_map, null, s_pos);
            }
        }

        if (s_pos.ContainsKey(n_pos.ToString()) is false)
        {
            s_pos.Add(n_pos.ToString(), 1);
        }

        delta.Rotate();
        n_pos = new Vec2(pos.X + delta.X, pos.Y + delta.Y);

        if (s_pos.TryGetValue(n_pos.ToString(), out var _))
            s_pos[n_pos.ToString()] += 1;

        g_map[pos.Y][pos.X] = '+';
    }
    g_map[pos.Y][pos.X] = delta.GetDirectionChar(g_map[pos.Y][pos.X]);

    return (g_map, null, s_pos);
}

static (Vec2, Vec2) init_vec(List<List<char>> input)
{
    Vec2? pos = null;
    Vec2? delta = null;

    for (int Y = 0; Y < input.Count; Y++)
    {
        for (int X = 0; X < input[Y].Count; X++)
        {
            if (input[Y][X] == '^')
            {
                input[Y][X] = '|';
                pos = new(X, Y);
                delta = new(0, -1);
            }
            else if (input[Y][X] == '>')
            {
                input[Y][X] = '-';
                pos = new(X, Y);
                delta = new(1, 0);
            }
            else if (input[Y][X] == 'v')
            {
                input[Y][X] = '|';
                pos = new(X, Y);
                delta = new(0, 1);
            }
            else if (input[Y][X] == '<')
            {
                input[Y][X] = '-';
                pos = new(X, Y);
                delta = new(-1, 0);
            }
        }
    }
    if (pos is null || delta is null)
    {
        throw new Exception($"This should never happen");
    }
    return (pos, delta);
}

static void print_map(List<List<char>> p_map)
{
    return;
    foreach (var row in p_map)
    {
        foreach (var ch in row)
        {
            if (ch == '|' || ch == '-' || ch == '+')
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.Write(ch);
                Console.ForegroundColor = ConsoleColor.White;
                continue;
            }
            else if (ch == '0')
            {
                Console.ForegroundColor = ConsoleColor.Magenta;
                Console.Write(ch);
                Console.ForegroundColor = ConsoleColor.White;
                continue;
            }
            Console.Write(ch);
        }
        Console.Write('\n');
    }
    Console.WriteLine("\n\n------------------------------------------------\n\n");
}

namespace types
{
    public class Vec2(int nX, int nY)
    {
        public int X { get; set; } = nX;
        public int Y { get; set; } = nY;
        public void Rotate()
        {
            if (X != 0)
            {
                Y = X;
                X = 0;
            }
            else
            {
                X = -Y;
                Y = 0;
            }
        }
        public char GetDirectionChar(char prev)
        {
            var resChar = X != 0 ? '-' : '|';
            if (prev != '.' && prev != resChar)
                return '+';
            return resChar;
        }
        public override bool Equals(object? obj)
        {
            if (obj is null)
                return false;

            Vec2 vec = obj as Vec2;

            return X == vec.X && Y == vec.Y;
        }
        public override string ToString()
        {
            return $"{X}_{Y}";
        }
    }
}
