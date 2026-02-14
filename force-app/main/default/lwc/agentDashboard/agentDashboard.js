import {LightningElement,track,wire} from 'lwc';
import fullCalendarPath from '@salesforce/resourceUrl/FullCalendar';
import dashboardSliderPath from '@salesforce/resourceUrl/DashboardSlider';
import {loadScript,loadStyle} from 'lightning/platformResourceLoader';
import getActivity from '@salesforce/apex/ActivityController.getMyAgencyEventsActivities';
import getMyCommunication from '@salesforce/apex/DashboardController.getMyCommunication';
import getDashboardDetails from '@salesforce/apex/DashboardController.getAgentDashboardDetails';
import getContent from '@salesforce/apex/Utilities.getContentByType';
import {colors} from "c/helpers";
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import { NavigationMixin } from 'lightning/navigation';
import trailblazerLabel from '@salesforce/label/c.trailheadapp_TrailblazerLoginURL';
// Added By Moh Sarfaraj for BPE-105
import AldarExpertAppointmentToggle from '@salesforce/label/c.AldarExpertAppointmentToggle';

export default class AgentDashboard extends NavigationMixin(LightningElement) {
	
	calendarIcon = resourcesPath + "/ALDARResources/svg/CalendarIcon.svg";
	whiteListViewIcon = resourcesPath + "/ALDARResources/svg/WhiteListViewIcon.svg";
	soldOutIcon = resourcesPath + "/ALDARResources/svg/SoldOut.svg";	
	GalleryIcon = resourcesPath + "/ALDARResources/svg/GalleryIcon.svg";
	dashboardLogo = resourcesPath + "/ALDARResources/png/dashboardLogo.png";
	viewPolicesIcon = resourcesPath + "/ALDARResources/svg/FilesIconOrangeBg.svg";
	knowYourTeamIcon = resourcesPath + "/ALDARResources/svg/KnowYourTeamIcon.svg";
	aldarExpertsIcon = resourcesPath + "/ALDARResources/svg/TrainingsIcon.svg";
	bookOpenHousIcon = resourcesPath + "/ALDARResources/svg/BookingsIcon.svg";
	testImage1 = resourcesPath + "/ALDARResources/jpeg/test.jpg";
	testImage2 = resourcesPath + "/ALDARResources/jpeg/test2.jpg";
	dashboardKpiPercentage = resourcesPath + "/ALDARResources/svg/dashboardKpiPercentage.svg";
	//barCodeIcon = resourcesPath + "/ALDARResources/png/barCode.png";
	personIcon = resourcesPath + "/ALDARResources/svg/PersonIcon.svg";
	showCustomerSatisfaction=false;
	showDetailsPage = false;
	slideData=[];
	startFrom;
	calendarEl;
	calendar;
	slideIndex;
	barCodeIcon;
	barCodeRedirect;
	// Added By Moh Sarfaraj for BPE-105
	@track aldarExpertAppointmentToggle;

	/* Calendar Data */
	eventData;
	@track events = [];
	@track eventsTypes = [];
	eventStatuses = [];
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
			this.handleEventFilterChange();
		}
		if (error) {
			console.error('Error: ' + JSON.stringify(error));
		}
	}
	handleEventFilterChange() {
		if (this.eventData) {
			let allSearchFields = this.template.querySelectorAll('.eventFilters');
			this.events = [];
			this.eventTypes = [];
			this.eventStatuses = [];
			this.eventStatuses.push({
				label: 'All',
				value: ''
			});
			for (let i = 0; i < this.eventData.length; i++) {
				//apply Filter
				var recordFiltered = false;
				for (let j = 0; j < allSearchFields.length; j++) {
					if (allSearchFields[j].value != undefined && allSearchFields[j].value != '') {
						if (this.eventData[i][allSearchFields[j].dataset.field] != allSearchFields[j].value) {
							recordFiltered = true;
							break;
						}
					}
				}
				if (!recordFiltered) {
					if (this.eventData[i].status && this.eventData[i].status != '' && this.eventStatuses.findIndex((item) => item.label === this.eventData[i].status) === -1) {
						this.eventStatuses.push({
							label: this.eventData[i].status,
							value: this.eventData[i].status
						});
					}
					this.events.push(this.eventData[i]);
				}
			}
			//this.calendarData = [...this.calendarData];
			this.initEventTypes();
			this.calendar.refetchEvents();
		}
	}
	/* Calendar END Data */
	/*Communication Start */
	months = {
		0: 'January',
		1: 'February',
		2: 'March',
		3: 'April',
		4: 'May',
		5: 'June',
		6: 'July',
		7: 'August',
		8: 'September',
		9: 'October',
		10: 'November',
		11: 'December'
	}
	@track communicationsArray;
	@wire(getMyCommunication)
	wiredCommunication({
		data,
		error
	}) {
		if (data) {
			this.communicationsArray = [];
			for (let i = 0; i < data.length; i++) {
				var startDate = new Date(data[i].LastModifiedDate);
				this.communicationsArray.push({
					id: data[i].CommunicationTemplate__r.Id, //id:1
					title: data[i].CommunicationTemplate__r.Title__c,
					bodyText: data[i].CommunicationTemplate__r.PlainTextBody__c,
					date: this.padTo2Digits(startDate.getDate()) + ' ' + this.months[startDate.getMonth()] + ' ' + startDate.getFullYear()
				});
			}
		}
		if (error) {
			console.error('Error: ' + JSON.stringify(error));
		}

	}
	/*Communication Start */
	/* Dashboard details */
	dashboardDetails;
	@wire(getDashboardDetails)
	wiredDBDetails({
		data,
		error
	}) {
		if (data) {
			this.dashboardDetails = data;
			// Added by Moh Sarfaraj for BPE-240
			//this.barCodeIcon = 'https://chart.googleapis.com/chart?chs=100x100&cht=qr&chld=L|1&chl='+(data.agentId?data.agentId:'');
			//this.barCodeRedirect = 'https://chart.googleapis.com/chart?chs=500x500&cht=qr&chld=L|1&chl='+(data.agentId?data.agentId:'');
			this.barCodeIcon = 'https://image-charts.com/chart?chs=150x150&cht=qr&chl='+(data.agentId?data.agentId:'');
			this.barCodeRedirect = 'https://image-charts.com/chart?chs=500x500&cht=qr&chl='+(data.agentId?data.agentId:'');
		}
		if (error) {
			console.error('Error: ' + JSON.stringify(error));
		}
	}
	/* Dashboard Details End */
	/* Annoucments */
	@track sliderImaegsArray = []
	@wire(getContent, {
		page: 0,
		pageSize: 3,
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
				var hasPromotion = false;
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
			}
		}
		if (error) {
			console.error('Error: ' + JSON.stringify(error));
		}
	}
	/* Annoucments END */
	/* Upcoming event */
	get upcomingLaunchesEvents() {
		var valuesToreturn = [];
		this.slideData=[];
		var extraVals = [];
		var extraSliderVals = [];
		if (this.eventData) {
			var today = new Date();
			for (let i = (this.eventData.length - 1);
				(i >= 0 && valuesToreturn.length != 3); i--) {
				
				var tempObj = {
					id: i + 1,
					index: i + 1,
					bgImage: this.eventData[i].bgImage,
					upCommingLaunchFlag: this.eventData[i].eventType == 'Launch',
					newEventFlag: (this.eventData[i].eventType != 'Launch' && this.eventData[i].rawData.activityDetail.StartDate__c &&  (( new Date(this.eventData[i].rawData.activityDetail.StartDate__c) - new Date() ) / (1000 * 60 * 60 * 24))  > -1 ),
					newLaunchFlag: (this.eventData[i].eventType == 'Launch' && this.eventData[i].rawData.activityDetail.StartDate__c &&  (( new Date(this.eventData[i].rawData.activityDetail.StartDate__c) - new Date() ) / (1000 * 60 * 60 * 24))  > -30 ),
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
			if (valuesToreturn.length != 3 && extraVals.length > 0) {
				for (let i = (extraVals.length-1) ;(i >=0 && valuesToreturn.length != 3); i--) {
					extraVals[i].index =this.slideData.length+1;
					valuesToreturn.push(extraVals[i]);
					extraSliderVals[i].index =this.slideData.length+1;
					this.slideData.push(extraSliderVals[i]);

				}
			}
		}
		return valuesToreturn;
	}
	/*
	upcomingLaunchesEvents=[
	{id:1,index:1,bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)",upCommingLaunchFlag:true,newEventFlag:false,newLaunchFlag:false,title:"Water’s Edge",description:"Lorem ipsum dolor sit amet, elit consectetuer adipiscing. Aenean commodo...",launchDate:"12/02/2022"}
	,{id:2,index:2,bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)",upCommingLaunchFlag:false,newEventFlag:true,newLaunchFlag:false,title:"Mayan Openhouse",description:"Lorem ipsum dolor sit amet, elit consectetuer adipiscing.",launchDate:"12/02/2022"}
	,{id:3,index:3,bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)",upCommingLaunchFlag:false,newEventFlag:false,newLaunchFlag:true,title:"Yes Acres, The Mongolias",description:"Lorem ipsum dolor sit amet, elit consectetuer adipiscing. Aenean commodo...",launchDate:"12/02/2022"}
	];*/
	/*
	@track communicationsArray=[
	    {id:1,title:"Pending Request for Case Management",bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget.",date:"13th Feb, 2022"},
	    {id:2,title:"Approval for Lead creation",bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula. Aenean massa ...",date:"12th Feb, 2022"},
	    {id:3,title:"Approval for New Agent",bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor....",date:"11th Feb, 2022"},
	    {id:4,title:"Approval for New Agent2",bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor....Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor....Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor....",date:"10th Feb, 2022"},
	    {id:5,title:"Approval for New Agent3",bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor....Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor....",date:"9th Feb, 2022"}
	]
	*/
	quickLinkArray = [{
		id: 1,
		icon: this.viewPolicesIcon,
		title: "View Policies",
		externallink: false,
		link: "../s/guidelines-and-policies"
	}, {
		id: 2,
		icon: this.knowYourTeamIcon,
		title: "Meet Aldar Team",
		externallink: false,
		link: "../s/contact-us"
	}, //{
		//id: 3,
		//icon: this.aldarExpertsIcon,
		//title: "Aldar Experts",
		//externallink: true,
		//link: "https://events.aldar.com/"
	//},
	{
		id: 4,
		icon: this.aldarExpertsIcon,
		title: "Training Program",
		externallink: true,
		link: trailblazerLabel
	}, ];
	connectedCallback() {
		// Added By Moh Sarfaraj for BPE-105
		this.aldarExpertAppointmentToggle = AldarExpertAppointmentToggle === 'true'? true : false;
		setTimeout(() => {
			//this.initEventTypes();
			this.slideIndex = 1;
			this.showSlides(this.slideIndex);
		}, 3000);
	}
	async renderedCallback() {
		// this.template.querySelectorAll('.image-side');
		 setTimeout(() => {
		this.setBackgroundImage('image-side');
		this.setBackgroundImage('mySlides');
	}, 500);

		const promise0 = await new Promise((resolve, reject) => {
			setTimeout(resolve, 100, loadStyle(this, dashboardSliderPath));
		});
		const promise1 = await new Promise((resolve, reject) => {
			setTimeout(resolve, 110, loadScript(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/core/main.js'));
		});
		const promise2 = await new Promise((resolve, reject) => {
			setTimeout(resolve, 120, loadScript(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/daygrid/main.js'));
		});
		const promise3 = await new Promise((resolve, reject) => {
			setTimeout(resolve, 130, loadScript(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/interaction/main.js'));
		});
		const promise4 = await new Promise((resolve, reject) => {
			setTimeout(resolve, 140, loadStyle(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/core/main.css'));
		});
		const resourcesToLoad = [promise0, promise1, promise2, promise3, promise4];
		await Promise.all(resourcesToLoad).then(() => {
			try {
				if (this.calendar) {
					this.calendar.destroy();
				}
			} catch (error) {
				console.error('Error calendar init', error);
			}
		}).then(() => {
			this.initializeCalendar();
			this.setEventTypesColors();
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
	initializeCalendar() {
		this.calendarEl = this.template.querySelector(".calendar");
		this.calendar = new FullCalendar.Calendar(this.calendarEl, {
			height: 270,
			 contentHeight: 'auto',
			plugins: ["dayGrid"],
			initialView: 'dayGridMonth',
			events: (info, successCallback, failureCallback) => {
				successCallback(this.events);
			},
		}, );
		this.calendar.render();
	}
	setEventTypesColors() {
	
		this.eventsTypes.forEach((item) => {
			let eventType = item.eventTypeId;
			this.template.querySelectorAll(`[data-id=${eventType}]`).forEach((element) => {
				if(!element.classList.contains("event-lable")){
					element.style.backgroundColor = item.color;
				  }else{
					element.style.color = item.color;
				  }
			})
		})
	}
	initEventTypes() {
		this.events.forEach((item) => {
			if (this.eventsTypes.filter(e => e.eventTypeId === item.eventTypeId).length == 0) {
				this.eventsTypes.push(item);
			}
		});
		this.eventsTypes = [...this.eventsTypes];
	}
	setBackgroundImage(className) {
		//console.clear();
		const divs = this.template.querySelectorAll(`.${className}`);
		if (divs) {
			for (let index = 0; index < divs.length; index++) {
				divs[index].style.backgroundImage = divs[index].getAttribute("data-bgimg");
				if(index !=0 && className == "mySlides"){
				divs[index].style.display="none";
			}
			}
		}
	}

	openDetailsPage(event) {
		document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {
			detail: {
				showNavigationTab: false,
				currentStep: "activties"
			}
		}));
		let startItem = event.currentTarget.dataset.index;
		this.startFrom = Number(startItem);
		setTimeout(() => {
			this.showDetailsPage = true;
		}, 200)
	}
	handleCloseEvent(event) {
		// to close modal set isModalOpen tarck value as false
		//this event has been fired from the modal component it self
		this.showDetailsPage = event.detail.isOpen;
	}


	changeShowCustomerSatisfaction(){
		this.showCustomerSatisfaction=true;
	}

	get showMainContainer(){
		return !(this.showCustomerSatisfaction || this.showDetailsPage);
	}


	CloseCustomerSatisfaction(event){
		
		this.showCustomerSatisfaction=event.detail.isOpen;
	}
	get eventsLength(){
		return this.events.length > 0;
	}
	get upcomingLaunchesEventsLength(){
		return this.upcomingLaunchesEvents.length > 0;
	}
	get communicationsArrayLength(){
		return this.data.length > 0;
	}
		
	openCommunication(event) {
		console.log('event.detail.value -> '+event.target.value)
		sessionStorage.setItem("communicationId", event.target.value );
		this.navigateToHomePage();
	}

	navigateToHomePage() {
		window.location.href = '/s/communications';
		
		/*this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'communications'
            }
        });*/
    }
	
	// Added By Moh Sarfaraj for BPE-105 starts
	@track bookAppiontment = false;

	bookAppointment(event){
		this.bookAppiontment = true;
	}

	handleCloseEvent(event){
		// alert(JSON.stringify(event.detail))
		let details = event.detail;
		this.bookAppiontment = details.isOpen;
	}
	// Added By Moh Sarfaraj for BPE-105 end

	handleLeadclick(event){
		sessionStorage.setItem("dashboardAction", "openCreateLead" );
		window.open("../s/manage-leads", "_self");
	}
}