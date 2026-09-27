pub fn parse_csv_line(line: &str) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    let mut cur = String::new();
    let mut in_quotes = false;
    let mut iter = line.chars().peekable();
    while let Some(ch) = iter.next() {
        match ch {
            '"' if in_quotes => {
                if iter.peek() == Some(&'"') {
                    cur.push('"');
                    iter.next();
                } else {
                    in_quotes = false;
                }
            }
            '"' => in_quotes = true,
            ',' if !in_quotes => {
                out.push(cur.trim().to_string());
                cur.clear();
            }
            _ => cur.push(ch),
        }
    }
    out.push(cur.trim().to_string());
    out
}

pub fn parse_csv(text: &str) -> Vec<Vec<String>> {
    text.lines()
        .filter(|l| !l.trim().is_empty())
        .map(parse_csv_line)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_csv_handles_quotes() {
        let rows = parse_csv("name,price\n\"Ayam Goreng\",10\nNasi,24");
        assert_eq!(rows.len(), 3);
        assert_eq!(rows[1][0], "Ayam Goreng");
        assert_eq!(rows[1][1], "10");
    }
}
