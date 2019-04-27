function [stim_vals, example] = number_assessment(input_images, area_format)
    %   function for assessing the value of five dimensions within 
    %   dot images used for numerosity studies
    %   input:
    %       input_images: x-by-y-by-n matrix of dot images, where n is the
    %       number of images. note that rbg images are not supported.
    %       
    %       area_format: string, ["c_hull"] or "circular. 
    %       "c_hull" is the convex hull, "circular" is the 
    %       smallest circle that covers all dots
    %
    %   output:
    %       stim_vals: n-by-5 array, where each column corresponds to a
    %           a different dimension: 
    %               1 - dot area (in % of input image size) 
    %               2 - total dot area (in % of input image size) 
    %               3 - convex_hull (in % of input image size)
    %               4 - mean occupancy (convex_hull/numerosity)
    %               5 - numerosity
    %       example: struct with input example and convex hull
    
    if nargin < 2
        area_format = 'c_hull';
    else
    end
    
    num_images = size(input_images,3);
    
    % assess area and size, looping over images
    stim_vals = zeros(num_images,5);
    for i = 1:size(input_images,3)
        temp_img = input_images(:,:,i);
        mask = zeros(size(temp_img));
        mask(temp_img ~= mode(temp_img(:))) = 1;
        c_hull = bwconvhull(mask);
        strct = regionprops(mask,'PixelList'); % coordinates of convex hull
        test = strct.PixelList;        
        dots = bwlabel(mask,4);
        
        % 1. dot size (will be adjusted down below)
        stim_vals(i,1) = numel(mask);
        % loop over dots
        for q = 1:max(dots(:))
            temp_size = length(find(dots == q)); % just grab smallest dot (dot should be about the same size, but can overlap)
            % normalize by array size
            temp_size = temp_size./numel(mask) * 100;
            if stim_vals(i,1) > temp_size
                stim_vals(i,1) = temp_size;
            else
            end
        end
        
        % 2. area, number of dot pixels
        stim_vals(i,2) = numel(find(dots>0));
        % normalize by image size 
        stim_vals(i,2) = stim_vals(i,2)./numel(mask) * 100;
        
        % 3. convex hull
        if strcmp(area_format, 'circular')
            % use 'circular' estimate:
            [bound_c,bound_r] = minboundcircle(test(:,1),test(:,2));        
            stim_vals(i,3) = ceil(bound_r^2*pi);
        else
            % use actual convex hull
            stim_vals(i,3) = length(find(c_hull == 1));
        end
        
        % normalize by image size 
        stim_vals(i,3) = stim_vals(i,3)./numel(mask) * 100;
        
        % 5. numerosity, just count the number of dots
        stim_vals(i,5) = length(unique(dots))-1;
        
        % 4. density = convex_hull/numerosity
        stim_vals(i,4) = stim_vals(i,3)./(stim_vals(i,5));
    end
    
    example.input = input_images(:,:,1);            
    mask = zeros(size(input_images(:,:,1)));
    mask(input_images(:,:,1) ~= mode(input_images(:,:,1))) = 1;
    c_hull = bwconvhull(mask);            
    example.hull = input_images(:,:,1);
    example.hull(~c_hull) = 0.5;
end

