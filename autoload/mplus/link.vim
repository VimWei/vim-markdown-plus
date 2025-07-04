vim9script

export def WikiLinkToggle(type: string)
    # 1. 获取操作范围的行号
    var line1 = getpos("'<")[1]
    var line2 = getpos("'>")[1]

    # 2. 在这个行范围内搜索所有的链接
    var links_in_range: list<any> = wiki#link#get_all_from_range(line1, line2)

    # 3. 根据搜索结果进行决策
    if !empty(links_in_range)
        # 如果在范围内找到了至少一个链接，则用户的意图是删除。
        # 为了使 toggle 行为可预测，我们只操作找到的第一个链接。
        var link_to_remove = links_in_range[0]
        call(link_to_remove.remove, [])
    else
        # 如果没有找到任何链接，则用户的意图是创建链接。
        wiki#link#transform_operator(type)
    endif
enddef
