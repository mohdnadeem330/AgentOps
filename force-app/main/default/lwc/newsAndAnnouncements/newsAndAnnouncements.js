import { LightningElement ,wire,track} from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import basePath from '@salesforce/community/basePath';
import getContent from '@salesforce/apex/Utilities.getContentByType';
export default class NewsAndAnnouncements extends LightningElement {

    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    calendar = resourcesPath + "/ALDARResources/svg/CalendarIcon.svg";
    yearOptions;
    monthOptions;
    @track tableData;
    @track showSpinner = false;
    @track showDetailsPage=false;

    calendarIcon = resourcesPath + "/ALDARResources/svg/CalendarIcon.svg";
    downloadIcon = resourcesPath + "/ALDARResources/svg/DownloadIcon.svg";
    virtualTourIcon = resourcesPath + "/ALDARResources/svg/VirtualTourIcon.svg";
    galleryIcon = resourcesPath + "/ALDARResources/svg/GalleryIcon_2.svg";
    socialMediaIcon = resourcesPath + "/ALDARResources/svg/SocialMediaIcon.svg";
    externalIcon = resourcesPath + "/ALDARResources/svg/ExternallinksIcon.svg";
    viewPoliciesIcon = resourcesPath + "/ALDARResources/svg/ViewPoliciesIcon.svg";

    startFrom;

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
    newsData=[];
    newsDataSorted=[];
    testPhoto1 = resourcesPath + "/ALDARResources/png/BackgroundImage.png";
    slideData=[];
    //slideDataSorted=[];
/*
    array=[
        {
          id: 1,
          index:1,
          slideShowImage: this.testPhoto1,
          bodyTitle: "Water’s Edge Roadshow",
          bodyDescription: "​This is your chance to choose from studio to 3 – bedroom apartments at Water’s Edge on Yas Island, with only a 5% down payment. The water front community is ideally situated on its own promenade and canal, in the heart of Yas Island just next to the Yas Park. It will feature landscaped gardens, fully equipped gyms, Pools and a jogging track. The boardwalk will be lined up with cafes, restaurants, and shops catering to all tastes.",
          bodyCardTitle: "Event Timings:",
          bodyCardFromDate: "30/01/2022",
          bodyCardFromTime: "1.30 pm",
    
          bodyCardToDate: "07/02/2022",
          bodyCardToTime: "5.00 pm",
          subCards:
            [{
                showIt:true,
              icon: this.downloadIcon,
              title: "Brand Guidelines",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.virtualTourIcon,
              title: "Virtual Tour",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]

            },
            {
                showIt:true,
              icon: this.galleryIcon,
              title: "Gallery",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:false,
              icon: this.socialMediaIcon,
              title: "Social Media Posts",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:false,
              icon: this.externalIcon,
              title: "External Links",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:false,
              icon: this.viewPoliciesIcon,
              title: "Sales Presentation",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            }]
    
    
        },
        {
          id: 2,
          index:2,
          slideShowImage: this.testPhoto1,
          bodyTitle: "Water’s Edge Roadshow 2",
          bodyDescription: "​This is your chance to choose from studio to 3 – bedroom apartments at Water’s Edge on Yas Island, with only a 5% down payment. The water front community is ideally situated on its own promenade and canal, in the heart of Yas Island just next to the Yas Park. It will feature landscaped gardens, fully equipped gyms, Pools and a jogging track. The boardwalk will be lined up with cafes, restaurants, and shops catering to all tastes.",
          bodyCardTitle: "Event Timings:",
          bodyCardFromDate: "30/01/2022",
          bodyCardFromTime: "1.30 pm",
    
          bodyCardToDate: "07/02/2022",
          bodyCardToTime: "5.00 pm",
          subCards:
            [{
              showIt:true,
              icon: this.downloadIcon,
              title: "Brand Guidelines",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.virtualTourIcon,
              title: "Virtual Tour",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.galleryIcon,
              title: "Gallery",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.socialMediaIcon,
              title: "Social Media Posts",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.externalIcon,
              title: "External Links",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.viewPoliciesIcon,
              title: "Sales Presentation",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            }]
    
        },
        {
          id: 3,
          index:3,
          slideShowImage: this.testPhoto1,
          bodyTitle: "Water’s Edge Roadshow 3",
          bodyDescription: "​This is your chance to choose from studio to 3 – bedroom apartments at Water’s Edge on Yas Island, with only a 5% down payment. The water front community is ideally situated on its own promenade and canal, in the heart of Yas Island just next to the Yas Park. It will feature landscaped gardens, fully equipped gyms, Pools and a jogging track. The boardwalk will be lined up with cafes, restaurants, and shops catering to all tastes.",
          bodyCardTitle: "Event Timings:",
          bodyCardFromDate: "30/01/2022",
          bodyCardFromTime: "1.30 pm",
    
          bodyCardToDate: "07/02/2022",
          bodyCardToTime: "5.00 pm",
          subCards:
            [{
                showIt:true,
              icon: this.downloadIcon,
              title: "Brand Guidelines",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.virtualTourIcon,
              title: "Virtual Tour",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.galleryIcon,
              title: "Gallery",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.socialMediaIcon,
              title: "Social Media Posts",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:true,
              icon: this.externalIcon,
              title: "External Links",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            },
            {
                showIt:false,
              icon: this.viewPoliciesIcon,
              title: "Sales Presentation",
              links: [{id:1,name:"Google Website Link",link:"www.google.com"},{id:2,name:"PWC Website Link",link:"www.PWC Website Link.com"}]
            }]
    
        }
    
    
      ];
 */
    renderedCallback() {
        this.setBackgroundImage();
    }
    connectedCallback(){
        //this.initContent();
    }
    
    /*initContent(){
        getContent({ page: 0, pageSize: 25, topics : ['News'],language: 'en_US',filterby: 'Aldar_NewsAnnouncements'})
        .then(data => {
            var contentPath=basePath.replace('/s','');
            for(let i=0; i<data.length ;i++){
                console.log(data[i]);
                var publishDate = new Date( data[i].contentNodes.PublishDate.value )

                this.newsData.push({
                    id: data[i].contentKey,
                    title: data[i].contentNodes.Title.value,
                    body: data[i].contentNodes.ShortDescription.value,
                    date: publishDate,
                    bgImage: (contentPath + data[i].contentNodes.SmallBannerImage.url),
                    year:publishDate.getFullYear(),
                    month: this.months[publishDate.getMonth()],
                    content:  data[i].contentNodes.Title.value + ' '+ data[i].contentNodes.ShortDescription.value,
                });
            }
            console.log(this.newsData);
            this.handleFilterChange();
        })
        .catch(error => {
            console.log(error);
            this.newsData =undefined;
        });
    }*/
    padTo2Digits(num) {
        return num.toString().padStart(2, '0');
      }
    formatDate(date) {
        return [
          this.padTo2Digits(date.getMonth() + 1),
          this.padTo2Digits(date.getDate()),
          date.getFullYear(),
        ].join('/');
    }
    @wire(getContent, { page: 0, pageSize: 25 /*, topics : ['News','Announcement']*/,language: 'en_US',filterby: 'Aldar_NewsAnnouncements'})
    wiredContent({ data, error }) {
        this.showSpinner = true;
        if (data) {
         
            //var contentPath=basePath.replace('/s','');
            for(let i=0; i<data.length ;i++){
              

                var publishDate = new Date( data[i].contentNodes.PublishDate.value )

                this.newsData.push({
                    id: data[i].contentKey,
                    title: data[i].contentNodes.Title.value,
                    body: data[i].contentNodes.ShortDescription.value,
                    date: this.formatDate(publishDate),
                    bgImage: `url(..${data[i].contentNodes.SmallBannerImage.url})` ,
                    year:publishDate.getFullYear(),
                    month: this.months[publishDate.getMonth()],
                    content:  data[i].contentNodes.Title.value.toLowerCase() + ' '+ data[i].contentNodes.ShortDescription.value.toLowerCase(),
                    index:i+1
                });
                //slide Data
                this.slideData.push({
                                    id: data[i].contentKey,
                                    index:i+1,
                                    slideShowImage: (data[i].contentNodes.LargeBannerImage.url.split(":")[0] =="http" || data[i].contentNodes.LargeBannerImage.url.split(":")[0] =="https")?data[i].contentNodes.LargeBannerImage.url: '..'+data[i].contentNodes.LargeBannerImage.url,
                                    bodyTitle: data[i].contentNodes.Title.value,
                                    bodyDescription:  data[i].contentNodes.LongDescription.value,
                                    bodyCardTitle: "Event Timings:",
                                    bodyCardFromDate: this.formatDate(publishDate),
                                    bodyCardFromTime: "",
                            
                                    bodyCardToDate: "",
                                    bodyCardToTime: "",
                                    subCards:
                                    [{
                                        showIt:false,
                                        icon: this.downloadIcon,
                                        title: "Brand Guidelines",
                                        link: ""
                                    },
                                    {
                                        showIt:false,
                                        icon: this.virtualTourIcon,
                                        title: "Virtual Tour",
                                        link: ""
                                    },
                                    {
                                        showIt:false,
                                        icon: this.galleryIcon,
                                        title: "Gallery",
                                        link: ""
                                    },
                                    {
                                        showIt:false,
                                        icon: this.socialMediaIcon,
                                        title: "Social Media Posts",
                                        link: ""
                                    },
                                    {
                                        showIt:false,
                                        icon: this.externalIcon,
                                        title: "External Links",
                                        link: ""
                                    },
                                    {
                                        showIt:false,
                                        icon: this.viewPoliciesIcon,
                                        title: "Sales Presentation",
                                        link: ""
                                    }]
                            
                            
                                });

            }
            this.newsDataSorted = this.newsData.sort((a,b)=>Date(b.date) - Date(a.date));
            this.newsData = this.newsDataSorted;

            //this.slideDateSorted = this.slideData.sort((a,b)=>Date(b.date) - Date(a.date));
            //this.slideData = this.slideDataSorted;
        
            this.handleFilterChange();
        }
        if (error) {
            console.error('Error: ' + JSON.stringify(error));
        }
        this.showSpinner = false;
    }
    
    handleFilterChange(){
        
        if(this.newsData){
            let allSearchFields = this.template.querySelectorAll('.newsFilters');
            this.tableData=[];
            this.yearOptions=[];
            this.monthOptions=[];
            for(let i=0; i<this.newsData.length ;i++){
                //apply Filter
                var recordFiltered=false;
                for(let j = 0; j < allSearchFields.length; j++) {
                    
                    if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                        if(allSearchFields[j].dataset.field =='content' && (this.newsData[i][allSearchFields[j].dataset.field].search(allSearchFields[j].value.toLowerCase()) == -1 ) ){
                            recordFiltered=true;
                            break;
                        }else  if(allSearchFields[j].dataset.field !='content' && this.newsData[i][allSearchFields[j].dataset.field] != allSearchFields[j].value){
                            recordFiltered=true;
                            break;
                        }
                        
                    }

                    
                    
                }
                if(!recordFiltered){
                    if(this.newsData[i].year && this.newsData[i].year!='' && this.yearOptions.findIndex((item) => item.label === this.newsData[i].year) === -1 ){
                        this.yearOptions.push({ label: this.newsData[i].year, value: this.newsData[i].year+'' });
                    }
                    if(this.newsData[i].month && this.newsData[i].month!='' && this.monthOptions.findIndex((item) => item.label === this.newsData[i].month) === -1 ){
                        this.monthOptions.push({ label: this.newsData[i].month, value: this.newsData[i].month });
                        //this.yearOptions.push({ label: this.newsData[i].month, value: this.newsData[i].month });
                    }
                    this.tableData.push(this.newsData[i]);
                }
            }
        }
        
    }
    clearFilter(){
        let allSearchFields = this.template.querySelectorAll('.newsFilters');
        for(let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value='';
        }
        this.handleFilterChange();
    }
     /*=
        [
            {
                id: 1,
                title: "Aldar takes complete control of Khidmah",
                body: "Aldar Properties today announces that it has acquired 40% of Khidmah - one of the UAE’s leading integrated property services companies - taking its total ownership to 100%.",
                date: "03/02/2022",
                bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
                "url(../../resource/ALDARResources/ALDARResources/png/Image1.png)"

            },
            {
                id: 2,
                title: "Aldar creates region’s largest diversified real estate investment company - Aldar Investments",
                body: "• Follows Government decree enabling asset ownership by Aldar Investments • 100% owned subsidiary with AED 20 billion of revenue generating assets • Will raise capital ...",
                date: "03/02/2022",
                bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"

            },
            {
                id: 3,
                title: "Aldar launches 10 billion masterplan - Al Ghadeer",
                body: "Over 14,000 homes to be delivered over 15 years First neighbourhood of 611 homes on sale at Cityscape Abu Dhabi – maisonette prices start from AED290,000 ...",
                date: "03/02/2022",
                bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"

            },
            {
                id: 4,
                title: "Mamsha",
                body: "Aldar Properties today announces that it has acquired 40% of Khidmah - one of the UAE’s leading integrated property services companies - taking its total ownership to 100%.",
                date: "03/02/2022",
                bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"

            },
            {
                id: 5,
                title: "Mamsha",
                body: "• Follows Government decree enabling asset ownership by Aldar Investments • 100% owned subsidiary with AED 20 billion of revenue generating assets • Will raise capital ...",
                date: "03/02/2022",
                bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"

            },
            {
                id: 6,
                title: "Mamsha",
                body: "Over 14,000 homes to be delivered over 15 years First neighbourhood of 611 homes on sale at Cityscape Abu Dhabi – maisonette prices start from AED290,000 ...",
                date: "03/02/2022",
                bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"

            }
        ]*/

        setBackgroundImage() {
            //console.clear();
            const divs = this.template.querySelectorAll('.image-side');
            if (divs) {
                for (let index = 0; index < divs.length; index++) {
                    divs[index].style.backgroundImage=divs[index].getAttribute("data-bgimg");
                    if(this.newsData[index].soldOut){
                        divs[index].style.filter="brightness(50%)";
                      }
                                                                }
                      }
        }

        openDetailsPage(event){
            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:false,currentStep:"news-and-announcements" }}));
      
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

}