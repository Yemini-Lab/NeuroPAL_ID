function style_node(tree, node, style)
    if isvalid(node)
        if ~any(isvalid(node.Parent))
            node = findobj(tree, 'NodeData', node.NodeData);
        end
        
        last_style_table_entry = find(ismember([tree.StyleConfigurations.TargetIndex{:}], node));
        if ~isempty(last_style_table_entry)
            removeStyle(tree, last_style_table_entry);
        end

        addStyle(tree, style, "node", node);
    end
end