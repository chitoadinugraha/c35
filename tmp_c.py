def strip_line_comment(line):
    bytes_ = line.encode("utf-8")
    i = 0
    in_string = False
    while i < len(bytes_):
        b = bytes_[i]
        if b == ord("'"):
            if in_string:
                if i + 1 < len(bytes_) and bytes_[i + 1] == ord("'"):
                    i += 2
                    continue
                in_string = False
            else:
                in_string = True
            i += 1
            continue
        if not in_string and b == ord("-") and i + 1 < len(bytes_) and bytes_[i + 1] == ord("-"):
            return line[:i].rstrip()
        i += 1
    return line

exec(open(r"D:/c35/tmp_run_inst.py").read().split("def strip_line_comment")[0].replace("def strip_line_comment(line):", ""))
# patch sql_stmts to use new strip - reload from migrate logic inline
