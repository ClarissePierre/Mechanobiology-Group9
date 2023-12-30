roi_length=roiManager("count");
for (i=0; i<roi_length; i++){
	if (i%1000 == 0){
		print("Processing roi: " + i);
	}
	roiManager("Select", i);
	roiManager("Measure");	
}
