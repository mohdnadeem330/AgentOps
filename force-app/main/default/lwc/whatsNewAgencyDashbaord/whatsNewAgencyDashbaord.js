import { LightningElement, track,wire } from 'lwc';
import dashboardSliderPath from '@salesforce/resourceUrl/DashboardSlider';
import {loadStyle} from 'lightning/platformResourceLoader';
import WhatsNewTestImage1 from '@salesforce/resourceUrl/WhatsNewTestImage1';
import WhatsNewTestImage2 from '@salesforce/resourceUrl/WhatsNewTestImage2';
import getActivity from '@salesforce/apex/ActivityController.getMyAgencyEventsActivities';
import {colors} from "c/helpers";
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getContent from '@salesforce/apex/Utilities.getContentByType';



export default class WhatsNewAgencyDashbaord extends LightningElement {


    personIcon = resourcesPath + "/ALDARResources/svg/PersonIcon.svg";
    showDetailsPage = false;
    slideIndex;

	/*
    sliderImaegsArray=[
        {id:1,index:1,
        imageSrc:"url(../resource/ALDARResources/ALDARResources/jpeg/test.jpg)",
        title:"Gear up for the upcoming Team Sales Contest!",
        description:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa." ,promotionFlag:false},
        {id:2,index:2,imageSrc:"url(../resource/ALDARResources/ALDARResources/jpeg/test2.jpg)",title:"Residential II",
        description:"Reflection II is one of two identical towers that make a bold statement on the skyline. From smart studios to sophisticated three-beds, every apartment is designed with urban style and a balcony that looks out over sea."
        ,promotionFlag:true
    },
        {id:3,index:3,imageSrc:"url(../resource/ALDARResources/ALDARResources/jpeg/test.jpg)",title:"test",description:"test",promotionFlag:false }
    
    ];
	*/
		/* Annoucments */
		@track showSpinner = false;
		@track sliderImaegsArray = [];
		@track whatsNewImagesArray=[];
		@wire(getContent, {
			page: 0,
			pageSize: 5,
			language: 'en_US',
			filterby: 'Aldar_NewsAnnouncements'
		})
		wiredContent({
			data,
			error
		}) {
			if (data) {
				//var contentPath=basePath.replace('/s','');
				for (let i = 0; i < data.length; i++) {
					console.log(data[i]);
					if(i<3){
						var hasPromotion = false
						if(data[i].associations && data[i].associations.topics){
							for (let j = 0; j < data[i].associations.topics.length; j++) {
								if (data[i].associations.topics[j].name === 'Promotion') {
									hasPromotion = true;
									break;
								}
							}
						}
						this.sliderImaegsArray.push({
							id: i + 1,
							index: i + 1,
							imageSrc: `url(..${data[i].contentNodes.SmallBannerImage.url})`,
							title: data[i].contentNodes.Title.value,
							description: data[i].contentNodes.ShortDescription.value,
							promotionFlag: hasPromotion
						});
					}else{
						this.whatsNewImagesArray.push({
							id: i + 1,
							index: i + 1,
							imageSrc: `url(..${data[i].contentNodes.SmallBannerImage.url})`,
							title: data[i].contentNodes.Title.value,
							description: data[i].contentNodes.ShortDescription.value,
							promotionFlag: hasPromotion
						});
					}
				}
				if(this.whatsNewImagesArray.length == 0 && this.sliderImaegsArray.length != 0 ){
					this.whatsNewImagesArray.push(this.sliderImaegsArray[this.sliderImaegsArray.length-1]);
				}
			}
			if (error) {
				console.error('Error: ' + JSON.stringify(error));
			}
		}
		/* Annoucments END */

    /*whatsNewImagesArray=[
        {id:1,
        index:1,
        imageSrc: `url(${WhatsNewTestImage1})`,
        title:"Aldar takes complete control of Khidmah",
        description:"Aldar Properties today announces that it has acquired 40% of Khidmah - one of the UAE’s leading integra…"
        },
        {id:2,
        index:2,
        imageSrc: `url(${WhatsNewTestImage2})`,
        title:"The big day has finally come! New Broker Portal has arrived",
        description:"Aldar Properties PJSC (شركة الدار العقارية Sharikah al-Dār..."
        }
    ];*/
	/*
    upcomingLaunchesEvents=[
    {id:1,index:1,bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)",upCommingLaunchFlag:true,newEventFlag:false,newLaunchFlag:false,title:"Water’s Edge",description:"Lorem ipsum dolor sit amet, elit consectetuer adipiscing. Aenean commodo...",launchDate:"12/02/2022"}
    ,{id:2,index:2,bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)",upCommingLaunchFlag:false,newEventFlag:true,newLaunchFlag:false,title:"Mayan Openhouse",description:"Lorem ipsum dolor sit amet, elit consectetuer adipiscing.",launchDate:"12/02/2022"}
    ,{id:3,index:3,bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)",upCommingLaunchFlag:false,newEventFlag:false,newLaunchFlag:true,title:"Yes Acres, The Mongolias",description:"Lorem ipsum dolor sit amet, elit consectetuer adipiscing. Aenean commodo...",launchDate:"12/02/2022"}
    ,{id:4,index:4,bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)",upCommingLaunchFlag:false,newEventFlag:false,newLaunchFlag:true,title:"Water’s Edge",description:"Lorem ipsum dolor sit amet, elit consectetuer adipiscing. Aenean commodo...",launchDate:"12/02/2022"}
    ];*/
		/* Upcoming event */
		padTo2Digits(num) {
			return num.toString().padStart(2, '0');
		}
		formatDate(date) {
			return [
				this.padTo2Digits(date.getDate()),
				this.padTo2Digits(date.getMonth() + 1),
				date.getFullYear(),
			].join('/');
		}
		msToTime(duration) {
			var milliseconds = parseInt((duration % 1000) / 100),
				seconds = Math.floor((duration / 1000) % 60),
				minutes = Math.floor((duration / (1000 * 60)) % 60),
				hours = Math.floor((duration / (1000 * 60 * 60)) % 24);
			let timeAMPM = (hours > 12) ? 'PM' : 'AM';
			hours = (hours > 12) ? hours - 12 : hours;
			return this.padTo2Digits(hours) + ":" + this.padTo2Digits(minutes) + ' ' + timeAMPM;
		}
		@wire(getActivity)
	wiredActivity({
		data,
		error
	}) {
		if (data) {
			this.eventData = [];
            var colormapping={};
			var colorCounter = -1;
			for (let i = 0; i < data.length; i++) {
                if(!colormapping[data[i].activityDetail.Type__c]){colorCounter++;}
				var startDate = new Date(data[i].activityDetail.StartDate__c);
				this.eventData.push({
					id: i + 1,
					title: data[i].activityDetail.Name,
					start: startDate.getFullYear() + '-' + this.padTo2Digits(startDate.getMonth() + 1) + '-' + this.padTo2Digits(startDate.getDate()), // this.formatDate(startDate),
					color: colormapping[data[i].activityDetail.Type__c] ? colormapping[data[i].activityDetail.Type__c] : colors[colorCounter],
					eventType: data[i].activityDetail.Type__c,
					eventTypeId: data[i].activityDetail.Type__c.replace(/\s/g, ''),
					eventDescription: data[i].activityDetail.ShortDescription__c,
					status: data[i].activityDetail.Status__c,
					recordTypeName: data[i].activityDetail.RecordType.Name,
					bgImage: data[i].relatedDocuments.Gallery.length > 0 ? `url(${data[i].relatedDocuments.Gallery[0].link})` : '',
					rawData : data[i]
				});
			}
			//this.handleEventFilterChange();
		}
		if (error) {
			console.error('Error: ' + JSON.stringify(error));
		}
	}

		get upcomingLaunchesEvents() {
			var valuesToreturn = [];
			this.slideData=[];
			var extraVals = [];
			var extraSliderVals = [];
			if (this.eventData) {
				var today = new Date();
				for (let i = (this.eventData.length - 1);
					(i >= 0 && valuesToreturn.length != 4); i--) {
					
					var tempObj = {
						id: i + 1,
						index: i + 1,
						bgImage: this.eventData[i].bgImage,
						upCommingLaunchFlag: this.eventData[i].eventType == 'Launch',
						newEventFlag: (this.eventData[i].eventType != 'Launch' && this.eventData[i].rawData.activityDetail.StartDate__c &&  (( new Date(this.eventData[i].rawData.activityDetail.StartDate__c) - new Date() ) / (1000 * 60 * 60 * 24))  > -1),
						newLaunchFlag:(this.eventData[i].eventType == 'Launch' && this.eventData[i].rawData.activityDetail.StartDate__c &&  (( new Date(this.eventData[i].rawData.activityDetail.StartDate__c) - new Date() ) / (1000 * 60 * 60 * 24))  > -30 ),
						title: this.eventData[i].title,
						description: this.eventData[i].eventDescription,
						launchDate: this.eventData[i].start
						
					};
					var sliderObj ={
							id: this.eventData[i].rawData.contentKey,
							index:i+1,
							slideShowImage: this.eventData[i].rawData.relatedDocuments.Gallery.length > 0 ? this.eventData[i].rawData.relatedDocuments.Gallery[0].link :'',
							bodyTitle: this.eventData[i].rawData.activityDetail.Name,
							bodyDescription:  this.eventData[i].rawData.activityDetail.Description__c,
							bodyCardTitle: "Event Timings:",
							bodyCardFromDate: this.eventData[i].rawData.activityDetail.StartDate__c ? this.formatDate( new Date(this.eventData[i].rawData.activityDetail.StartDate__c)):'',
							bodyCardFromTime: this.eventData[i].rawData.activityDetail.StartTime__c || this.eventData[i].rawData.activityDetail.StartTime__c ==0 ? this.msToTime(this.eventData[i].rawData.activityDetail.StartTime__c) : '',
					
							bodyCardToDate: this.eventData[i].rawData.activityDetail.EndDate__c ? this.formatDate( new Date(this.eventData[i].rawData.activityDetail.EndDate__c)):'',
							bodyCardToTime: this.eventData[i].rawData.activityDetail.EndTime__c || this.eventData[i].rawData.activityDetail.EndTime__c ==0 ? this.msToTime(this.eventData[i].rawData.activityDetail.EndTime__c) : '',
							subCards:
							[{
								showIt:this.eventData[i].rawData.relatedDocuments['Brand Guidelines'].length > 0 ,
								icon: this.downloadIcon,
								title: "Brand Guidelines",
								links: this.eventData[i].rawData.relatedDocuments['Brand Guidelines']
							},
							{
								showIt: this.eventData[i].rawData.activityDetail.VirtualTourLink__c ? true:false,
								icon: this.virtualTourIcon,
								title: "Virtual Tour",
								links: [{id:1,name:"Virtual Tour",link:this.eventData[i].rawData.activityDetail.VirtualTourLink__c}]
							},
							{
								showIt:this.eventData[i].rawData.relatedDocuments.Gallery.length > 0 ,
								icon: this.galleryIcon,
								title: "Gallery",
								links: this.eventData[i].rawData.relatedDocuments.Gallery
							},
							{
								showIt: this.eventData[i].rawData.activityDetail.SocialMediaLink1__c ? true:false,
								icon: this.socialMediaIcon,
								title: "Social Media Posts",
								links: [{id:1,name:"Social Media Link",link: this.eventData[i].rawData.activityDetail.SocialMediaLink1__c}]
							},
							{
								showIt: this.eventData[i].rawData.activityDetail.ExternalLink__c ? true:false,
								icon: this.externalIcon,
								title: "External Links",
								links: [{id:1,name:"External Link",link:this.eventData[i].rawData.activityDetail.ExternalLink__c}]
							},
							{
								showIt: this.eventData[i].rawData.relatedDocuments.Documents.length > 0 ,
								icon: this.viewPoliciesIcon,
								title: "Other Documents",
								links: this.eventData[i].rawData.relatedDocuments.Documents
							}]
						};
					if (this.eventData[i].recordTypeName === 'Event' && (new Date(this.eventData[i].start) > today)) {
						tempObj.newLaunchFlag = false;
						tempObj.index = this.slideData.length+1;
						valuesToreturn.push(tempObj);
						sliderObj.index = this.slideData.length+1;
						this.slideData.push(sliderObj);
					} else if (this.eventData[i].recordTypeName === 'Event') {
						tempObj.upCommingLaunchFlag = false;
						extraVals.push(tempObj);
						extraSliderVals.push(sliderObj);
					}
				}
				if (valuesToreturn.length != 4 && extraVals.length > 0) {
					for (let i = (extraVals.length-1) ;(i >=0 && valuesToreturn.length != 4); i--) {
						extraVals[i].index =this.slideData.length+1;
						valuesToreturn.push(extraVals[i]);
						extraSliderVals[i].index =this.slideData.length+1;
						this.slideData.push(extraSliderVals[i]);
	
					}
				}
			}
			return valuesToreturn;
		}

    connectedCallback() {
		setTimeout(() => {
			//this.initEventTypes();
			this.slideIndex = 1;
			this.showSlides(this.slideIndex);
		}, 3000);
	}
    async renderedCallback() {
		
		 setTimeout(() => {
		this.setBackgroundImage('image-side');
		this.setBackgroundImage('mySlides');
        this.setBackgroundImage('news-card');
    
	}, 500);

		const promise0 = await new Promise((resolve, reject) => {
			setTimeout(resolve, 100, loadStyle(this, dashboardSliderPath));
		});
		
	
		const resourcesToLoad = [promise0];
		await Promise.all(resourcesToLoad).then(() => {
			try {
				console.log("Loaded ......");
			} catch (error) {
				console.error('Error calendar init', error);
			}
		}).catch(error => {
			console.error('Error promise all', error);
		});
	}

    plusSlides() {
		let n = 1;
		this.showSlides(this.slideIndex += n);
	}
	
	currentDiv(n) {
		this.showSlides(this.slideIndex = n);
	}

	showSlides(n) {
	
		var i;
		var x = this.template.querySelectorAll(".mySlides");
		var dots = this.template.querySelectorAll(".demo");
	
		if (n > x.length) {
			this.slideIndex = 1
		}
		if (n < 1) {
			this.slideIndex = x.length
		}
		for (i = 0; i < x.length; i++) {
			x[i].style.display = "none";
		}
		for (i = 0; i < dots.length; i++) {
			dots[i].className = dots[i].className.replace(" w3-white", "");
		}
		x[this.slideIndex - 1].style.display = "block";
		dots[this.slideIndex - 1].className += " w3-white";
	}

	goToClickedImage(event){
		let n=Number(event.target.dataset["index"] || event.currentTarget.dataset.index);

		var i;
		var x = this.template.querySelectorAll(".mySlides");
		var dots = this.template.querySelectorAll(".demo");
	
		if (n > x.length) {
			this.slideIndex = 1
		}
		if (n < 1) {
			this.slideIndex = x.length
		}
		for (i = 0; i < x.length; i++) {
			x[i].style.display = "none";
		}
		for (i = 0; i < dots.length; i++) {
			dots[i].className = dots[i].className.replace(" w3-white", "");
		}
		this.slideIndex=n;
		x[n - 1].style.display = "block";
		dots[n - 1].className += " w3-white";

	}
    setBackgroundImage(className) {
		//console.clear();
		const divs = this.template.querySelectorAll(`.${className}`);

        console.log("className:",className);
console.log("length:",divs.length);

		if (divs) {
			for (let index = 0; index < divs.length; index++) {

                console.log("===>>>>>>>",divs[index].getAttribute("data-bgimg"));
				divs[index].style.backgroundImage = divs[index].getAttribute("data-bgimg");
				if(index !=0 && className == "mySlides"){
				divs[index].style.display="none";
			}
			}
		}
	}

  

	

	
	openDetailsPage(event){
    document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:false,currentStep:"whats-new" }}));
    this.showDetailsPage=true;

    let startItem=event.currentTarget.dataset.index;
    

    this.startFrom=Number(startItem);

           setTimeout(() => {
               this.showDetailsPage=true;
        }, 200);
  }
  handleCloseEvent(event){
          // to close modal set isModalOpen tarck value as false
          //this event has been fired from the modal component it self
          this.showDetailsPage = event.detail.isOpen;
      
  }
get upcomingLaunchesEventsLength(){
	return this.upcomingLaunchesEvents.length > 0;
}
	
}