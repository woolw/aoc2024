string content = File.ReadAllText("input");

int count = content.Split('\n')
    .ToList()
    .Where(rep =>
    {
        List<int> data = rep
            .Split(' ')
            .Select(int.Parse)
            .ToList();

        if (data.Count < 2)
            return true;

        bool dec = data[0] > data[1];
        for (int i = 0; i < data.Count - 1; i++)
        {
            int diff = Math.Abs(data[i] - data[i + 1]);
            if (dec != (data[i] > data[i + 1]) || diff == 0 || diff > 3)
                return false;
        }

        return true;
    }).Count();

Console.WriteLine($"Part one: {count}");


bool damperedReportCheck(List<int> data, bool isFullRep = false)
{
    if (data.Count < 2)
        return true;

    bool dec = data[0] > data[1];
    for (int i = 0; i < data.Count - 1; i++)
    {
        int diff = Math.Abs(data[i] - data[i + 1]);
        if (dec != (data[i] > data[i + 1]) || diff == 0 || diff > 3)
            return isFullRep && (damperedReportCheck([.. data.Skip(1)]) || damperedReportCheck([.. data.Where((_, idx) => idx != i)]) || damperedReportCheck([.. data.Where((_, idx) => idx != (i + 1))]));
    }

    return true;
}

count = content.Split('\n')
    .ToList()
    .Where(rep =>
    {
        List<int> data = rep
            .Split(' ')
            .Select(int.Parse)
            .ToList();

        return damperedReportCheck(data, true);
    }).Count();

Console.WriteLine($"Part two: {count}");