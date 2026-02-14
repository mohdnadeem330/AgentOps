import {LightningElement,track,wire } from 'lwc';
import fullCalendarPath from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getActivity from '@salesforce/apex/ActivityController.getMyAgencyActivity';
import   {colors} from "c/helpers";

export default class Activities extends LightningElement {
    calendarIcon = resourcesPath + "/ALDARResources/svg/CalendarIcon.svg";
    downloadIcon = resourcesPath + "/ALDARResources/svg/DownloadIcon.svg";
    virtualTourIcon = resourcesPath + "/ALDARResources/svg/VirtualTourIcon.svg";
    galleryIcon = resourcesPath + "/ALDARResources/svg/GalleryIcon_2.svg";
    socialMediaIcon = resourcesPath + "/ALDARResources/svg/SocialMediaIcon.svg";
    externalIcon = resourcesPath + "/ALDARResources/svg/ExternallinksIcon.svg";
    viewPoliciesIcon = resourcesPath + "/ALDARResources/svg/ViewPoliciesIcon.svg"; 
    //Filter js Start Here//
    buttonClicked;
    @track cssClass = 'filters-items';
    @track iconName = ''; 
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.cssClass = this.buttonClicked ? 'filters-items showfillter' : 'filters-items';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    } 
    //Filter js End Here// 
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    calendarIcon = resourcesPath + "/ALDARResources/svg/CalendarIcon.svg";
    calendarEl;
    calendar;
    loadedFlag = false;
    showDetailsPage=false;
    @track eventData = [];
    @track tableData = [];
    @track calendarData = [];
    @track slideData = [];
    eventTypes=[];
    eventStatuses=[];
    startFrom;
  /*
    @track events = [{
            id: 1,
            title: 'Roadshow',
            start: '2022-05-14',
            color: '#4C2BFF',
            eventType: "Events",
            eventDescription: "Aenean commodo ligula eget dolor. Aenean massa …"
  
        },
        {
            id: 2,
            title: 'Broker Training',
            start: '2022-05-15',
            color: '#00B705',
            eventType: "Launches",
            eventDescription: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean massa …"
        },
        {
            id: 3,
            title: 'Mayan Launch',
            start: '2022-05-16',
            color: '#FF6522',
            eventType: "Activities",
            eventDescription: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit."
        }
    ];
  
    array = [{
            id: 1,
            title: "Aldar takes complete control of Khidmah",
            body: "Aldar Properties today announces that it has acquired 40% of Khidmah - one of the UAE’s leading integrated property services companies - taking its total ownership to 100%.",
            date: "03/02/2022",
            bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)",
            status: "Open"
  
        },
        {
            id: 2,
            title: "Aldar creates region’s largest diversified real estate investment company - Aldar Investments",
            body: "• Follows Government decree enabling asset ownership by Aldar Investments • 100% owned subsidiary with AED 20 billion of revenue generating assets • Will raise capital ...",
            date: "03/02/2022",
            bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)",
            status: "Open"
  
        },
        {
            id: 3,
            title: "Aldar launches 10 billion masterplan - Al Ghadeer",
            body: "Over 14,000 homes to be delivered over 15 years First neighbourhood of 611 homes on sale at Cityscape Abu Dhabi – maisonette prices start from AED290,000 ...",
            date: "03/02/2022",
            bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)",
            status: "Completed"
  
        }
    ]
  */
    @track eventsTypes = [];
    // previousStepIcon = resourcesPath + "/ALDARResources/svg/CompleteStepIcon.svg";
  
    connectedCallback() {
        
    }
    initEventTypes(){
      this.calendarData.forEach((item) => {
          if (this.eventsTypes.filter(e => e.eventTypeId === item.eventTypeId).length == 0) {
              this.eventsTypes.push(item);
          }
      });
      this.eventsTypes = [...this.eventsTypes];
    }
    padTo2Digits(num) {
      if(num===0){return '00'}
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
     
      let timeAMPM = (hours>12)?'PM':'AM';
      hours =  (hours>12)? hours-12 :hours;
      return this.padTo2Digits(hours) + ":" + this.padTo2Digits(minutes) + ' ' +timeAMPM;
    }
    @wire(getActivity)
      wiredContent({ data, error }) {
          if (data) {
            var colormapping={};
			      var colorCounter = -1;
            for(let i=0; i<data.length ;i++){
              if(!colormapping[data[i].activityDetail.Type__c]){colorCounter++;}
              var startDate = new Date(data[i].activityDetail.StartDate__c )
              var endDate = new Date( data[i].activityDetail.EndDate__c )
              this.eventData.push({ id: i+1,
                                    title: data[i].activityDetail.Name,
                                    body: data[i].activityDetail.ShortDescription__c,
                                    startDateNonFormatted:startDate,
                                    endDateNonFormatted:endDate,
                                    date: this.formatDate(startDate),
                                    endDate: this.formatDate(endDate),
                                    type:  data[i].activityDetail.Type__c,
                                    bgImage: data[i].relatedDocuments.Gallery.length > 0 ? `url(${data[i].relatedDocuments.Gallery[0].link})` :'',
                                    status: data[i].activityDetail.Status__c,
                                    color: colormapping[data[i].activityDetail.Type__c] ? colormapping[data[i].activityDetail.Type__c] : colors[colorCounter], //(data[i].activityDetail.CalendarColorCode__c && data[i].activityDetail.CalendarColorCode__c != '') ? data[i].activityDetail.CalendarColorCode__c : '#4C2BFF',
                                    index:i+1
                                  });
               this.slideData.push({
                      id: data[i].contentKey,
                      index:i+1,
                      slideShowImage: data[i].relatedDocuments.Gallery.length > 0 ? data[i].relatedDocuments.Gallery[0].link :'',
                      bodyTitle: data[i].activityDetail.Name,
                      bodyDescription:  data[i].activityDetail.Description__c,
                      bodyCardTitle: "Event Timings:",
                      bodyCardFromDate: data[i].activityDetail.StartDate__c ? this.formatDate(startDate):'',
                      bodyCardFromTime: data[i].activityDetail.StartTime__c || data[i].activityDetail.StartTime__c ==0 ? this.msToTime(data[i].activityDetail.StartTime__c) : '',
              
                      bodyCardToDate: data[i].activityDetail.EndDate__c ? this.formatDate(endDate):'',
                      bodyCardToTime: data[i].activityDetail.EndTime__c || data[i].activityDetail.EndTime__c ==0 ? this.msToTime(data[i].activityDetail.EndTime__c) : '',
                      subCards:
                        [{
                          showIt:data[i].relatedDocuments['Brand Guidelines'].length > 0 ,
                          icon: this.downloadIcon,
                          title: "Brand Guidelines",
                          links: data[i].relatedDocuments['Brand Guidelines']
                        },
                        {
                          showIt: data[i].activityDetail.VirtualTourLink__c ? true:false,
                          icon: this.virtualTourIcon,
                          title: "Virtual Tour",
                          links: [{id:1,name:"Virtual Tour",link:data[i].activityDetail.VirtualTourLink__c}]
                        },
                        {
                          showIt:data[i].relatedDocuments.Gallery.length > 0 ,
                          icon: this.galleryIcon,
                          title: "Gallery",
                          links: data[i].relatedDocuments.Gallery
                        },
                        {
                          showIt: data[i].activityDetail.SocialMediaLink1__c ? true:false,
                          icon: this.socialMediaIcon,
                          title: "Social Media Posts",
                          links: [{id:1,name:"Social Media Link",link: data[i].activityDetail.SocialMediaLink1__c}]
                        },
                        {
                          showIt: data[i].activityDetail.ExternalLink__c ? true:false,
                          icon: this.externalIcon,
                          title: "External Links",
                          links: [{id:1,name:"External Link",link:data[i].activityDetail.ExternalLink__c}]
                        },
                        {
                          showIt: data[i].relatedDocuments.Documents.length > 0 ,
                          icon: this.viewPoliciesIcon,
                          title: "Other Documents",
                          links: data[i].relatedDocuments.Documents
                        }]
                  });
            }
            this.handleFilterChange();
          }
          if (error) {
              console.error('Error: ' + JSON.stringify(error));
          }
      }
      
      handleFilterChange(){
          
        if(this.eventData){
            let allSearchFields = this.template.querySelectorAll('.eventFilters');
            this.tableData=[];
            this.eventTypes=[];
            this.eventStatuses=[];
            this.calendarData =[];
            for(let i=0; i<this.eventData.length ;i++){
                //apply Filter
                var recordFiltered=false;
                for(let j = 0; j < allSearchFields.length; j++) {
                  if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                    if(this.eventData[i].date && this.eventData[i].date!=null && allSearchFields[j].dataset.field == 'startDateNonFormatted' ){
                      var d1 = new Date(this.eventData[i].startDateNonFormatted) ;
                      var d2 = new Date(allSearchFields[j].value) ;
                      if(d1 < d2){
                          recordFiltered=true;
                          break;
                      }
                    }else if(this.eventData[i].endDate && this.eventData[i].endDate !=null && allSearchFields[j].dataset.field == 'endDateNonFormatted'  ){
                        var d1 = new Date(this.eventData[i].endDateNonFormatted) ;
                        var d2 = new Date(allSearchFields[j].value) ;
                        if(d1 > d2){
                            recordFiltered=true;
                            break;
                        }
                        
                    }else if(this.eventData[i][allSearchFields[j].dataset.field] != allSearchFields[j].value){
                        recordFiltered=true;
                        break;
                    }
                  }  
                } 
                if(!recordFiltered){
                    if(this.eventData[i].type && this.eventData[i].type!='' && this.eventTypes.findIndex((item) => item.label === this.eventData[i].type) === -1 ){
                        this.eventTypes.push({ label: this.eventData[i].type, value: this.eventData[i].type });
                    }
                    if(this.eventData[i].status && this.eventData[i].status!='' && this.eventStatuses.findIndex((item) => item.label === this.eventData[i].status) === -1 ){
                        this.eventStatuses.push({ label: this.eventData[i].status, value: this.eventData[i].status });
                    }
                    this.tableData.push(this.eventData[i]);
                    this.calendarData.push({
                                          id: i+1,
                                          title: this.eventData[i].title,
                                          start: this.eventData[i].startDateNonFormatted.getFullYear() +'-'+ this.padTo2Digits(this.eventData[i].startDateNonFormatted.getMonth() +1)+'-'+ this.padTo2Digits(this.eventData[i].startDateNonFormatted.getDate()),
                                          color: this.eventData[i].color,
                                          eventType: this.eventData[i].type,
                                          eventDescription: this.eventData[i].body,
                                          eventTypeId:this.eventData[i].type.replace(/\s/g, '')
                                
                                      });
                }
                
            }
              this.calendarData = [...this.calendarData];
              this.initEventTypes();
              this.calendar.refetchEvents(); 
        }
        
    }
    clearFilter(){
        let allSearchFields = this.template.querySelectorAll('.eventFilters');
        for(let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value='';
        }
        this.handleFilterChange();
    }
  /*
    test() {
        this.events.push({
            id: 9,
            title: 'Roadshow',
            start: '2022-05-14',
            color: '#4C2BFF',
            eventType: "Events",
            eventDescription: "Aenean commodo ligula eget dolor. Aenean massa …"
  
        });
        this.events = [...this.events];
        this.calendar.refetchEvents();
    }
  */
    async renderedCallback() {
        this.setBackgroundImage();
  
        const promise1 = await new Promise((resolve, reject) => {
            setTimeout(resolve, 100, loadScript(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/core/main.js'));
        });
        const promise2 = await new Promise((resolve, reject) => {
            setTimeout(resolve, 110, loadScript(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/daygrid/main.js'));
        });
  
        const promise3 = await new Promise((resolve, reject) => {
            setTimeout(resolve, 120, loadScript(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/interaction/main.js'));
        });
        const promise4 = await new Promise((resolve, reject) => {
            setTimeout(resolve, 130, loadStyle(this, fullCalendarPath + '/fullcalendar-4.4.3/packages/core/main.css'));
        });
  
        const fullCalendarResources = [promise1, promise2, promise3, promise4];
        await Promise.all(fullCalendarResources).then(() => {
          try {

                if(this.calendar){
                   this.calendar.destroy();
                 } 
              
          } catch (error) {
              console.error('Error calendar init', error);
          }

      }).then(()=>{
        this.initializeCalendar();
        this.setEventTypesColors();
      }).catch(error => {
            console.error('Error promise all', error);
        });
    }
  
  
    initializeCalendar() {
  
        this.calendarEl = this.template.querySelector(".calendar");
        this.calendar = new FullCalendar.Calendar(this.calendarEl, {
  
                //   eventSources: [{ events:this.events}],
                plugins: ["dayGrid"],
                initialView: 'dayGridMonth',
                events: (info, successCallback, failureCallback) => {
  
  
  
                    successCallback(this.calendarData);
                },
  
            },
  
        );
  
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
  
    setBackgroundImage() {
        //console.clear();
        const divs = this.template.querySelectorAll('.image-side');
        if (divs) {
            for (let index = 0; index < divs.length; index++) {
              divs[index].style.backgroundImage = divs[index].getAttribute("data-bgimg");
            }
        }
    }
  
    openDetailsPage(event){

      document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:false,currentStep:"activities" }}));
this.showDetailsPage=true;
  
      let startItem=event.currentTarget.dataset.index;
    

     this.startFrom=Number(startItem);

            setTimeout(() => {
                this.showDetailsPage=true;
         }, 200)
    }
    handleCloseEvent(event){
            // to close modal set isModalOpen tarck value as false
            //this event has been fired from the modal component it self
            this.showDetailsPage = event.detail.isOpen;
            this.calendarData = [...this.calendarData];
            this.calendar.refetchEvents(); 
    }
  

}