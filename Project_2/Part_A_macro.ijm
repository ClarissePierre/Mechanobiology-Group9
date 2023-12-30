#@File(label="Select the avi file", style="file") avi_path
#@Integer(label="Frame range", value = 10000) frange
#@Integer(label="Gaussian blurring sigma", value = 1) gsigma1
#@Integer(label="Gaussian blurring sigma", value = 4) gsigma2
#@Integer(label="Variance filtering sigma", value = 3) vsigma
#@Integer(label="Local variance threshold (0-255)", value = 128) vthres

// 356953

function closeWindowNot(names_array) {
	openImages = getList("image.titles");
	
	// Loop through open images and close those not in the name array
	for (i = 0; i < openImages.length; i++) {
	    imageName = openImages[i];
	    indexist = false;
	    for (j = 0; j < names_array.length; j++) {
	    	if (names_array[j] == imageName) {
	    		indexist = true;
	    	}
	    }
	    if (indexist == false) {
	        selectWindow(imageName);
	        close();
    	}
	}
}

run("Close All");
img_name_raw = File.getName(avi_path);
img_name_raw = img_name_raw.replace(".tif","");
img_name = img_name_raw + "_s1";
img_archive_name = img_name + "_arc";
bgd_10_name = "bgd_10";
bgd_10_average_name = bgd_10_name + "_average";
open(avi_path);
rename(img_name_raw);
run("Duplicate...", "title=" + img_name + " duplicate range=1-" + frange + " use"); 
print("Resizing stack...");
rename(img_name);
run("Size...", "width=32 height=64 depth=" + frange +" constrain average interpolation=Bilinear");
selectImage(img_name);

// get the background img (average of first 10 frames)
print("Background subtraction...")
run("Duplicate...", "title=" + img_archive_name + " duplicate");
run("Duplicate...", "title=" + bgd_10_name + " duplicate range=1 use");
selectImage(bgd_10_name);
run("Gaussian Blur...", "sigma=" + gsigma1 + " stack");
run("Z Project...", "projection=[Average Intensity]");
rename(bgd_10_average_name);

// blur the target image
selectImage(img_name);
run("Gaussian Blur...", "sigma=" + gsigma1 + " stack");

// compute subtraction
imageCalculator("Subtract 32-bit stack", img_name, bgd_10_average_name);
img_sub_name = img_name + "_sub";
rename(img_sub_name);

// compute dog
print("DoG bandpass filtering");
selectImage(img_sub_name);
run("Duplicate...", "title=" + img_sub_name + "_2" + " duplicate");
run("Gaussian Blur...", "sigma=" + gsigma2 + " stack");
selectImage(img_sub_name + "_2");
run("Gaussian Blur...", "sigma=" + gsigma2*1.4 + " stack");
imageCalculator("Subtract 32-bit stack", img_sub_name, img_sub_name+"_2");
img_dg_name = img_sub_name + "_dg";
rename(img_dg_name);

// make this mechanism better
print("Compute local variance...");
setSlice(14);
run("Variance...", "radius=" + vsigma + " stack");
setOption("ScaleConversions", true);
run("8-bit");

img_subvar_name = img_name + "_subvar";
rename(img_subvar_name);
selectImage(img_subvar_name);

// get image dimension
getDimensions(width, height, channels, slices, frames); // time frame goes to slice
// get measurement
print("Analyzing particles...");
run("Measure Stack...");
rcount = getValue("results.count");

keeplist = "1";
for (tf=0; tf<rcount; tf++){
	if (tf % 10000 == 0){
		print("Processing frame: " + tf);
	}
	if (getResult("Max", tf) >= vthres) {
		keeplist = keeplist + "," + (tf+1);
	}
}

print(keeplist);

open(avi_path);
rename(img_name_raw);
names_array = newArray(img_name_raw);
closeWindowNot(names_array);
selectImage(img_name_raw);
run("Make Substack...", "slices=" + keeplist);
// run("Add Slice");