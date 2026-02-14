import {LightningElement,track,wire} from 'lwc';
import fullCalendarPath from '@salesforce/resourceUrl/FullCalendar';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import {loadScript,loadStyle} from 'lightning/platformResourceLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import BROKER_REQUEST_OBJECT from '@salesforce/schema/BrokerRequest__c';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getActivity from '@salesforce/apex/ActivityController.getMyAgencyEventsActivities';
import getMyCommunication from '@salesforce/apex/DashboardController.getMyCommunication';
import getAgencyDashboardDetails from '@salesforce/apex/DashboardController.getAgencyDashboardDetails';
import   {colors} from "c/helpers";
import { NavigationMixin } from 'lightning/navigation';
import trailblazerLabel from '@salesforce/label/c.trailheadapp_TrailblazerLoginURL';
// Added By Moh Sarfaraj for BPE-105
import AldarExpertAppointmentToggle from '@salesforce/label/c.AldarExpertAppointmentToggle';

export default class AgencyDashboard extends NavigationMixin(LightningElement) {
	whiteListViewIcon = resourcesPath + "/ALDARResources/svg/WhiteListViewIcon.svg";
	soldOutIcon = resourcesPath + "/ALDARResources/svg/SoldOut.svg";
	GalleryIcon = resourcesPath + "/ALDARResources/svg/GalleryIcon.svg";
	viewPolicesIcon = resourcesPath + "/ALDARResources/svg/FilesIconOrangeBg.svg";
	knowYourTeamIcon = resourcesPath + "/ALDARResources/svg/KnowYourTeamIcon.svg";
	aldarExpertsIcon = resourcesPath + "/ALDARResources/svg/TrainingsIcon.svg";
	bookOpenHousIcon = resourcesPath + "/ALDARResources/svg/BookingsIcon.svg";
	goldMediaIcon = resourcesPath + '/ALDARResources/svg/GoldMedalIcon.svg';
	chartIcon1 = resourcesPath + '/ALDARResources/svg/ChartIcon1.svg';
	chartIcon2 = resourcesPath + '/ALDARResources/svg/ChartIcon2.svg';
	calendarEl;
	calendar;


	ambassador = resourcesPath + '/ALDARResources/png/Ambassador.png';
	attache = resourcesPath + '/ALDARResources/png/Attache.png';
	consul = resourcesPath + '/ALDARResources/png/Consul.png';
	envoy = resourcesPath + '/ALDARResources/png/Envoy.png';
	// Added By Moh Sarfaraj for BPE-105
	@track aldarExpertAppointmentToggle;

	/* Calendar Data */
	eventData;
	@track events = [];
	@track eventsTypes = [];
	@track showSpinner = false;
	@track managerRequestOptionList = [];
	@track managerRequestType = '';
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
	@wire(getObjectInfo, { objectApiName: BROKER_REQUEST_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (error) {
            const err = error;
        } else if (data) {
            const rtis = data.recordTypeInfos;
            let marketingRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Marketing Reimbursement');
			let eventRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Event Request');
			this.managerRequestOptionList.push({ 'label': 'Marketing Reimbursement', 'value': marketingRT });
			this.managerRequestOptionList.push({ 'label': 'Event Request', 'value': eventRT });
        }
    };
	get managerRequestOptions() {
		return this.managerRequestOptionList.length > 0 ? this.managerRequestOptionList : [];
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
					color: colormapping[data[i].activityDetail.Type__c] ? colormapping[data[i].activityDetail.Type__c] : colors[colorCounter], //(data[i].activityDetail.CalendarColorCode__c && data[i].activityDetail.CalendarColorCode__c != '') ? data[i].activityDetail.CalendarColorCode__c : '#4C2BFF',
					eventType: data[i].activityDetail.Type__c,
					eventTypeId: data[i].activityDetail.Type__c.replace(/\s/g, ''),
					eventDescription: data[i].activityDetail.ShortDescription__c,
					status: data[i].activityDetail.Status__c,
					recordTypeName: data[i].activityDetail.RecordType.Name,
					bgImage: data[i].relatedDocuments.Gallery.length > 0 ? `url(${data[i].relatedDocuments.Gallery[0].link})` : ''
				});
				
			}
			this.handleEventFilterChange();
		}
		if (error) {
			console.error('Error: ' + JSON.stringify(error));
		}
	}
	isEnvoy=false;
	isAttach=false;
	isConsul=false;
	isAmbassador=false;
	isStandard=false;

	handleManagerRequest(event) {
		this.managerRequestType = event.target.value;
		window.open('../s/manage-request?type=' + this.managerRequestType, '_self');
	}

	onClickManagerRequest(event) {
		console.log('onClickManagerRequest');
		window.open('../s/manage-request?type=' + this.managerRequestType, '_self');
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
	/* Calendar Data */



	/*
	    @track eventsTypes = [];
	 eventStatuses=[];
	 @track events = [{
	    id: 1,
	    title: 'Roadshow',
	    start: '2022-05-14',
	    color: '#4C2BFF',
	    eventType: "Events",
	    eventTypeId:"Events",
	    eventDescription: "Aenean commodo ligula eget dolor. Aenean massa …"

	},
	{
	    id: 2,
	    title: 'Broker Training',
	    start: '2022-05-15',
	    color: '#00B705',
	    eventType: "Launches",
	    eventTypeId:"Launches",
	    eventDescription: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean massa …"
	},
	{
	    id: 3,
	    title: 'Mayan Launch',
	    start: '2022-05-16',
	    color: '#FF6522',
	    eventType: "Activities",
	    eventTypeId:"Activities",
	    eventDescription: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit."
	},
	{
	    id: 4,
	    title: 'Mayan Launch',
	    start: '2022-05-17',
	    color: '#FF6522',
	    eventType: "Activities",
	    eventTypeId:"Activities",
	    eventDescription: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit."
	},
	{
	    id: 5,
	    title: 'Mayan Launch',
	    start: '2022-05-18',
	    color: '#FF6522',
	    eventType: "Activities",
	    eventTypeId:"Activities",
	    eventDescription: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit."
	},
	{
	    id: 6,
	    title: 'Mayan Launch',
	    start: '2022-05-19',
	    color: '#FF6522',
	    eventType: "Activities",
	    eventTypeId:"Activities",
	    eventDescription: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit."
	}
	];
	*/
	/*
	kpisArray=[
	    {label:"Open Leads",value:"28"},
	    {label:"Open Opportunities",value:"09"},
	    {label:"Units Sold",value:"03"},
	    {label:"Total Sales Value",value:"117.5M"},
	    {label:"Commission Earned",value:"186.6M"},
	    {label:"Requests Pending",value:"12"}
	] */



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
	/*Communication END */


  /* Quick Links start */

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
	},
	// {
		//id: 3,
		//icon: this.aldarExpertsIcon,
		//title: "Aldar Experts",
		//externallink: true,
		//link: "https://events.aldar.com/"
	//}, 
	{
		id: 4,
		icon: this.bookOpenHousIcon,
		title: "Book Open House /Kiosk",
		externallink: false,
		link: "../s/manage-request"
	},{
		id: 5,
		icon: this.aldarExpertsIcon,
		title: "Training Program",
		externallink: true,
		link: trailblazerLabel
	}];

  /* Quick Links End */



	/* Basic Details and Ranking Table Start */
	@track tableData = [];
	@track selectedAccount = '';
	@track agencyDetails;
	@track kpisArray = [];
	@track selectedAccountRank ='0';
	@track childClassificationstatus = '';
	@track selectedAccountClassification = '';
	startDate;
	endDate;
	@track projectArray = [];
	@track projectSalesArray = [];
	@track projectCommissionArray = [];
	@track monthArray = [];
	@track monthWiseSales = [];
	initAgencyDetails() {
		this.projectArray = [];
		this.projectSalesArray = [];
		this.projectCommissionArray = [];
		this.monthArray=[];
		this.monthWiseSales=[];
		getAgencyDashboardDetails({
			accountId: this.selectedAccount,
			startDate: new Date(this.startDate),
			endDate: new Date(this.endDate)
		}).then(data => {
			this.agencyDetails = data;
			if (data.topAccountRanking) {
				this.tableData = [];
				for (let i = 0; i < data.topAccountRanking.length; i++) {
					this.tableData.push({
						id: i + 1,
						ranking: data.topAccountRanking[i].rank,
						agencyName: data.topAccountRanking[i].accountRecord.Name,
						classificationStatus: data.topAccountRanking[i].accountRecord.BrokerClassification__c ? data.topAccountRanking[i].accountRecord.BrokerClassification__r.Name : ''
					});
				}
				
			}
			this.kpisArray = data.kpiList;
			this.projectArray = data.projectList;
			this.projectSalesArray = data.salesByProject;
			this.projectCommissionArray = data.commissionbyProject;
			this.monthArray=[];
			for(let i = 1; i<data.monthValues.length; i++ ){
				this.monthArray.push(this.months[(data.monthValues[i]-1)]);
			}
			//this.monthArray=data.monthValues;
			this.monthWiseSales=data.totalSalesByMonth;
			
			this.initializeChart();
		}).then(data =>{
			this.getClassification();
		})
		.catch(error => {
			console.error('Error: ' + JSON.stringify(error));
		});
	}
	@track showchildAgentRanking = false;
	/* Ranking Table End */
	handleFilterChange() {
		this.showchildAgentRanking = false;
		this.startDate = undefined;
		this.endDate = undefined;
		this.selectedAccount = undefined;
		let allSearchFields = this.template.querySelectorAll('.agencyFilters');
		for (let i = 0; i < allSearchFields.length; i++) {
			if (allSearchFields[i].value != undefined && allSearchFields[i].value != '') {
				if (allSearchFields[i].dataset.field === 'startDate') {
					this.startDate = allSearchFields[i].value
				} else if (allSearchFields[i].dataset.field === 'endDate') {
					this.endDate = allSearchFields[i].value
				} else if (allSearchFields[i].dataset.field === 'selectedAccount') {
					this.selectedAccount = allSearchFields[i].value
				}
			}
		}
		for(let i=0; i<this.agencyDetails.childAccounts.length; i++){
			if(this.agencyDetails.childAccounts[i].value == this.selectedAccount && !this.agencyDetails.childAccounts[i].label.includes('Parent')){
				this.showchildAgentRanking = true;
				break;
			}
		}
		this.selectedAccountRank = this.agencyDetails.linkedAccountRanks[this.selectedAccount];
		this.selectedAccountClassification = this.agencyDetails.linkedAccountClassification[this.selectedAccount];
		//this.selectedAccountRank = this.agencyDetails
		this.initAgencyDetails();
	}

  /*Ranking Table columns */
  tableColumns = [{
		type: 'ranking',
		fieldName: 'ranking',
		label: 'Ranking',
		initialWidth: 70,
		cellAttributes: {
			class: 'ranking-cell' /*important for reponsive */
		}
	}, {
		type: 'text',
		fieldName: 'agencyName',
		label: 'Agency Name',
		cellAttributes: {
			class: 'agency-name-cell' /*important for reponsive */
		}
	}, {
		type: 'text',
		fieldName: 'classificationStatus',
		label: 'Classification Status',
		cellAttributes: {
			class: 'classification-status-cell' /*important for reponsive */
		}
	}, {
		type: 'id',
		/*fieldName: 'id',*/
		label: '',
		initialWidth: 10,
		cellAttributes: {
			class: 'column-id' /*important for reponsive */
		}
	}];

	/*
	tableData = [
	    {
	        id:1,
	        ranking:1,
	        agencyName: "Property Shop Investment LLC",
	        classificationStatus: "Envoy",
	        
	    },
	    {
	        id:2,
	        ranking: 2,
	        agencyName: "AL MIRA Real Estate Brokerage LLC",
	        classificationStatus: "Attachè",
	        
	    },
	    {
	        id:3,
	        ranking: 3,
	        agencyName: "Metropolitan Capital Real Estate",
	        classificationStatus: "Attachè",
	        
	    },
	    {
	        id:4,
	        ranking: 4 ,
	        agencyName: "Town properties",
	        classificationStatus: "Attachè",
	        
	    },
	    {
	        id:5,
	        ranking: 5,
	        agencyName: "Al Zaeem Commercial Brokers",
	        classificationStatus: "Consul",
	        
	    }
	]*/
	connectedCallback() {
		// Added By Moh Sarfaraj for BPE-105
		this.aldarExpertAppointmentToggle = AldarExpertAppointmentToggle === 'true'? true : false;
		
		var todayDate = new Date();
        this.startDate = todayDate.getFullYear() +'-01-01' ;
        this.endDate = todayDate.getFullYear() +'-'+ (todayDate.getMonth() +1).toString().padStart(2, '0') +'-'+ todayDate.getDate().toString().padStart(2, '0');

		this.initAgencyDetails();

  
		setTimeout(() => {
	
	


			this.initEventTypes();
		}, 500);
	}
	isChartJsInitialized = false;
	async renderedCallback() {
		const promise0 = await new Promise((resolve, reject) => {
			setTimeout(resolve, 100, loadScript(this, chartjs));
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
		//	this.initializeChart();
		}).catch(error => {
			console.error('Error promise all', error);
		});
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

  
	//TODO set colors based on color array
	initializeChart() {
		

    const data = {
      labels: [...this.projectArray],

      datasets: [{
        
        label: 'Total Sales Value by Project',
        data:  [...this.projectSalesArray],
        backgroundColor: colors,
        hoverOffset: 4
      }]
    };


		const config = {
			type: 'doughnut',
			data: data,
			options: {
				maintainAspectRatio: true,
				responsive: true,
				legend:{
					display:false,
				}
			}
		};
		const ctx1 = this.template.querySelector('canvas.chart1').getContext('2d');
		ctx1.canvas.width = 408;
		ctx1.canvas.height = 284;
		let chart1 = new window.Chart(ctx1, config);


		const data2 = {
			labels: [...this.projectArray],
			datasets: [{
				label: 'Commission Earned by Project',
				data: [...this.projectCommissionArray],
				backgroundColor: colors,
				hoverOffset: 4
			}]
		};
		const config2 = {
			type: 'doughnut',
			data: data2,
			options: {
				maintainAspectRatio: true,
				responsive: true,
				legend:{
					display:false,
				}
			}
		};
		const ctx2 = this.template.querySelector('canvas.chart2').getContext('2d');
		ctx2.canvas.width = 408;
		ctx2.canvas.height = 284;
		let chart2 = new window.Chart(ctx2, config2);
		const DATA_COUNT = 12;
		


		const datapoints = [...this.monthWiseSales];
		//const datapoints = [100,20000000,1213,123123,2344,354456,345345,2342234,232342,2234,1000]
		//this.monthArray=['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

		const ctx3 = this.template.querySelector('canvas.chart3').getContext('2d');
		ctx3.canvas.width = 986;
		ctx3.canvas.height = 284;
		const gradientBg = ctx3.createLinearGradient(0,0,0,400);
		gradientBg.addColorStop(0,'red');
		gradientBg.addColorStop(1,'green');

		const data3 = {
			labels: [...this.monthArray],
			
			datasets: [{
					// label: 'Monthly Sales Summary (in millions)',
					backgroundColor: '#008000', // 'rgba(136, 51, 255,0.2)',
					data: datapoints,
					borderColor: "#8833FF",
					fill: true,
					cubicInterpolationMode: 'monotone',
					tension: 0.4
		
				},
				
				/*, {
				      label: 'Cubic interpolation',
				      data: datapoints,
				      borderColor: "blue",
				      fill: false,
				      tension: 0.4
				    }, {
				      label: 'Linear interpolation (default)',
				      data: datapoints,
				      borderColor: "green",
				      fill: false
				    }*/
			]
		};
		const config3 = {
			type: 'bar',
			data: data3,
			options: {
				responsive: true,
				maintainAspectRatio: false,
				legend:{
					display:false,
				},
				plugins: {
					title: {
						display: true,
						text: 'Chart.js Line Chart - Cubic interpolation mode'
					},
				},
				interaction: {
					intersect: false,
				},
				scales: {
						yAxes: [{
						  scaleLabel: {
							display: true,
						  },
						  ticks: {
							display: true,
							autoSkip: false,
							callback: function(value, index, valuesArray) {
								if(value > 999 && value < 1000000){
									return (value/1000).toFixed(0) + 'K'; // convert to K for number from > 1000 < 1 million 
								}else if(value > 1000000){
									return (value/1000000).toFixed(0) + 'M'; // convert to M for number from > 1 million 
								}else if(value < 900){
									return value; // if value < 1000, nothing to do
								}
								
							}
						  }

						}]
				
				}
			},
		};
		
		let chart3 = new window.Chart(ctx3, config3);
	}

	
		/*
	
Ambassador: #96672F
Consul: #A00306
Attache: #9D9A93
Envoy: #BAA24F

	*/
	getClassification(){
        

        if(this.agencyDetails.accountClassification == "Envoy" ){
     this.isEnvoy=true;
     this.template.querySelector(".greeting-right-side").classList.add("envoy");
        }else if(this.agencyDetails.accountClassification == "Attache"){
     this.isAttach =true;
     this.template.querySelector(".greeting-right-side").classList.add("attache");

        }
        else if(this.agencyDetails.accountClassification == "Consul"){
            this.isConsul =true;
            this.template.querySelector(".greeting-right-side").classList.add("consul");

        }
        else if(this.agencyDetails.accountClassification == "Ambassador"){
            this.isAmbassador =true;
            this.template.querySelector(".greeting-right-side").classList.add("ambassador");

        }
        else if(this.agencyDetails.accountClassification == "Standard"){
            this.isStandard =true;
            //this.template.querySelector(".greeting-right-side").classList.add("standard");

        }
    
    }
	get isEventsEmpty(){
		console.log(this.events.length);
		return this.events.length == 0;
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
}