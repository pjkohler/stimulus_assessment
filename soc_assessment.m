function [resp_vals, example] = soc_assessment(input_images, exp_fov, round_factor, bandpass)
    %   function for assessing the estimated BOLD response 
    %   for any series of input images, 
    %   according to Kendrick Kay's soc model
    %   Requires that the soc model is on the path, can be downloaded
    %   from http://kendrickkay.net/socmodel/
    %
    %   input:
    %       input_images: x-by-y-by-n matrix of images, where n is the
    %                     number of images. 
    %                     note that rbg images are not supported.
    %       
    %       exp_fov:      field-of-view (aka diameter of the input images 
    %                     in degrees of visual angle). default: 10
    %       
    %       round_factor: how much to round by when down- or upscaling
    %                     default: 10
    %
    %       bandpass:     bandpass before feed to model true/[false]
    %                     
    %
    %   output:
    %       resp_vals: n-by-4 array, where the columns correspond to 
    %                  V1, V2, V3 and V4 responses.
    %       example: struct with input example and model response

    if nargin < 2
        exp_fov = 10;
    else
    end
    
    if nargin < 3
        round_factor = 10;
    else
    end
    
    if nargin < 4
        bandpass = false;
    else
    end
        
    % parameters from http://kendrickkay.net/socmodel/ (bottom): 
    sd_param = [0.9308, 1.0738, 1.4671, 2.1242]; 
    n_param = [0.1814, 0.1285, 0.1195, 0.1152]; 
    c_param = [0.9276, 0.9928, 0.9941, 0.9472];
    % corresponds to V1, V2, V3 and V4. 
    
    % variables from kkay's code:
    load('stimuli.mat', 'bpfilter');
           
    % downsample image to match Kendrick's images
    kay_res = 256;
    kay_fov = 12.7;
    
    if round_factor > 1
        new_size = round(kay_res/kay_fov*exp_fov/round_factor)*round_factor;
        % actual size 201.5748, use 200;
    else
        new_size = round(kay_res/kay_fov*exp_fov);
    end
    
    new_images = imresize(input_images, [new_size, new_size]);
    if bandpass
        % find background value
        bg_val = mode(new_images(:));
        % pad to avoid edge effects
        filt_images = padarray(new_images, [new_size/5, new_size/5], bg_val, 'both'); 
        filt_images = arrayfun(@(x) conv2(filt_images(:,:,x), bpfilter), 1:size(filt_images, 3),'uni',false);
        crop_val =  (size(filt_images{1},1)-new_size)/2;
        filt_images = cellfun(@(x) x(crop_val+1:crop_val+new_size,crop_val+1:crop_val+new_size), filt_images, 'uni', false);
        filt_images = cell2mat(reshape(filt_images, [1, 1, size(filt_images,2)]));
    else
        filt_images = double(new_images);
    end
    
    cache = [];
    resp_vals = zeros(length(filt_images),4);
    for v = 1:4    
        [temp_resp,cache] = socmodel(filt_images,new_size,[],1.2,{new_size/4 -1 1 8 2 .01 2 0}, ...
                            1,.5, sd_param(v), 1/sd_param(v), n_param(v), c_param(v), cache);                      
        resp_vals(:,v) = squeeze(mean(mean(temp_resp,1),2));
        if v == 1
            example.input = new_images(:,:,1);            
        else
        end
        example.resp(:,:,v) = temp_resp(:,:,1);
    end
end

