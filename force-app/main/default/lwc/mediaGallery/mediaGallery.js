import { LightningElement } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import testResource from '@salesforce/resourceUrl/testVideo';
const Project_Details_Page_Icons=resourcesPath+"/ALDARResources/svg/project-details-page-icons/";


export default class MediaGallery extends LightningElement {


    test1=Project_Details_Page_Icons+"TestImages/Capture1.PNG";
    test2=Project_Details_Page_Icons+"TestImages/Test2.PNG";
    testVideo = testResource ;

      videoesArray=[
        {id:1,index:1,poistionId:"#vslide-1",src:this.testVideo,label:"Test 1"},
        {id:2,index:2,poistionId:"#vslide-2",src:this.testVideo,label:"Test 2"},
        {id:3,index:3,poistionId:"#vslide-3",src:this.testVideo,label:"Test 3"},
        {id:4,index:4,poistionId:"#vslide-4",src:this.testVideo,label:"Test 4"},
        {id:5,index:5,poistionId:"#vslide-5",src:this.testVideo,label:"Test 5"},
        {id:6,index:6,poistionId:"#vslide-6",src:this.testVideo,label:"Test 6"},
        {id:7,index:7,poistionId:"#vslide-7",src:this.testVideo,label:"Test 7"},
        {id:8,index:8,poistionId:"#vslide-8",src:this.testVideo,label:"Test 8"}
    ];


    imagesArray=[
        {id:1,index:1,poistionId:"#slide-1",src:this.test1,label:"Test 1"},
        {id:2,index:2,poistionId:"#slide-2",src:this.test2,label:"Test 2"},
        {id:3,index:3,poistionId:"#slide-3",src:this.test1,label:"Test 3"},
        {id:4,index:4,poistionId:"#slide-4",src:this.test2,label:"Test 4"},
        {id:5,index:5,poistionId:"#slide-5",src:this.test1,label:"Test 5"},
        {id:6,index:6,poistionId:"#slide-6",src:this.test2,label:"Test 6"},
        {id:7,index:7,poistionId:"#slide-7",src:this.test1,label:"Test 7"},
        {id:8,index:8,poistionId:"#slide-8",src:this.test2,label:"Test 8"}
    ];





renderedCallback() {
    this.setBackgroundImage();
}


setBackgroundImage() {
    console.clear();
    const divs = this.template.querySelectorAll('.image-side');
    if (divs) {
        for (let index = 0; index < divs.length; index++) {
            divs[index].style.backgroundImage=divs[index].getAttribute("data-bgimg");
            if(this.array[index].soldOut){
                divs[index].style.filter="brightness(50%)";
              }
                                                        }
              }
}
}