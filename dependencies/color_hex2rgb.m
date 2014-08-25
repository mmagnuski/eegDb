function colores = color_hex2rgb(colora)

    colores = zeros(length(colora),3);
    
    % hexadec to decimal
    dig = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',...
        'A', 'B', 'C', 'D', 'E', 'F'};
    
    for c = 1:length(colora)
        hex = colora{c};
        
        for rgb = 1:3
            loc = rgb *2;
            piece = hex(loc-1:loc);
            
            % transform
            val = (find(strcmp(piece(1), dig))-1)*16 +...
                (find(strcmp(piece(2), dig))-1);
            colores(c,rgb) = val;
        end
    end