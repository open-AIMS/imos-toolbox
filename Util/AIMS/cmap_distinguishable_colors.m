function rgb = cmap_distinguishable_colors(N)

    % exlude white, black, yellow
    bg = [1 1 1; 0 0 0; 1 1 0];
    rgb = distinguishable_colors(N, bg);
    
end