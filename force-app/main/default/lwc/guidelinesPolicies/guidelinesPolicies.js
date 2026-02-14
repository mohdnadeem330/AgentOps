import { LightningElement,wire,track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getContent from '@salesforce/apex/Utilities.getContentByTopics';

export default class GuidelinesPolicies extends LightningElement {


    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    filterIcon=resourcesPath+ "/ALDARResources/svg/FilterIcon.svg";
    cardIcon = resourcesPath + "/ALDARResources/svg/FilesIconOrangeBg.svg";
    downloadIcon = resourcesPath + "/ALDARResources/svg/Download-Icon-no-bg.svg";

    policyData=[];
    @track tableData;
    @track showSpinner = false;
    typeOptions;
/*
array=[
{
    id:1,
    title:"Broker Classification Manual",
    date:"03/02/2022",
    subTitlte:"Document Type here",
    bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. asdfasdf ,asdffghjtyudfg fdghsetyfgdfg awasdfgsdfg",
    downloadLink:""
},
{
    id:2,
    title:"Brand Values & Guidelines",
    date:" 03/02/2022", 
    subTitlte:"Document Type here",
    bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. asdfasdf ,asdffghjtyudfg fdghsetyfgdfg awasdfgsdfg",
    downloadLink:""
},
{
    id:3,
    title:"Communication Guidelines",
    date:" 03/02/2022", 
    subTitlte:"Document Type here",
    bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. asdfasdf ,asdffghjtyudfg fdghsetyfgdfg awasdfgsdfg",
    downloadLink:""
},
{
    id:4,
    title:"Aldar Guidelines",
    date:" 03/02/2022", 
    subTitlte:"Document Type here",
    bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. asdfasdf ,asdffghjtyudfg fdghsetyfgdfg awasdfgsdfg",
    downloadLink:""
},
{
    id:5,
    title:"Project 1 Guidelines",
    date:" 03/02/2022", 
    subTitlte:"Document Type here",
    bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. asdfasdf ,asdffghjtyudfg fdghsetyfgdfg awasdfgsdfg",
    downloadLink:""
},
{
    id:6,
    title:"Project 2 Guidelines",
    date:" 03/02/2022", 
    subTitlte:"Document Type here",
    bodyText:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. asdfasdf ,asdffghjtyudfg fdghsetyfgdfg awasdfgsdfg",
    downloadLink:""
}
];*/
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
    @wire(getContent, { page: 0, pageSize: 100, topics : ['Policies','Procedure'],language: 'en_US',filterby: 'cms_document'})
    wiredContent({ data, error }) {
        this.showSpinner = true;
        if (data) {
            //var contentPath=basePath.replace('/s','');
            for(let i=0; i<data.length ;i++){
            
                this.policyData.push({
                    id:i+1,
                    title:data[i].contentNodes.title.value,
                    date: this.formatDate(new Date(data[i].publishedDate)), 
                    subTitlte:data[i].associations.topics[0].name,
                    bodyText: data[i].contentNodes.altText ? data[i].contentNodes.altText.value :'',
                    downloadLink:'..'+data[i].contentNodes.source.url,
                    content:(data[i].contentNodes.altText ? data[i].contentNodes.altText.value :'').toLowerCase()+''+data[i].contentNodes.title.value.toLowerCase()
                });


            }
            console.log(this.policyData);
            this.handleFilterChange();
            this.showSpinner = false;
        }
        if (error) {
            this.policyData=[];
            console.log('Error: ' + JSON.stringify(error));
            this.showSpinner = false;
        }
        
    }

    // Added By Moh Sarfaraj starts 
    showPreview = false;
    dynamicDocumentURL;
    titleForTheDocument = 'Preview Document';
    handlePreviewDocument(event){
        this.showPreview = true;
        // alert(event.currentTarget.dataset.id);
        //alert(JSON.stringify(this.policyData))
        const object = this.policyData.find(obj => obj.id == event.currentTarget.dataset.id);
        // let dL = this.policyData.filter(x => x.id === event.currentTarget.dataset.id).map(x => x.downloadLink);
        //alert(JSON.stringify(object))
        this.dynamicDocumentURL = object.downloadLink; // set dynamic url based on id
    }
    
    handlePreviewEvent(event){
        // alert(event.detail.isOpen);
        this.showPreview = event.detail.isOpen;
    }
    // Added By Moh Sarfaraj end

    clearFilter(){
        let allSearchFields = this.template.querySelectorAll('.policyFilters');
        for(let j = 0; j < allSearchFields.length; j++) {
            allSearchFields[j].value='';
        }
        this.handleFilterChange();
    }

    handleFilterChange(){
        let allSearchFields = this.template.querySelectorAll('.policyFilters');
        this.tableData=[];
        this.typeOptions=[];
        if(this.policyData){
            for(let i=0; i<this.policyData.length ;i++){
                //apply Filter
                var recordFiltered=false;
                for(let j = 0; j < allSearchFields.length; j++) {
                    
                    if(allSearchFields[j].value!=undefined && allSearchFields[j].value!='' ){
                        console.log(allSearchFields[j].dataset.field);
                        console.log(this.policyData[i][allSearchFields[j].dataset.field]);
                        console.log(allSearchFields[j].value.toLowerCase());
                        if(allSearchFields[j].dataset.field =='content' && (this.policyData[i][allSearchFields[j].dataset.field].search(allSearchFields[j].value.toLowerCase()) == -1 ) ){
                            recordFiltered=true;
                            break;
                        }else  if(allSearchFields[j].dataset.field !='content' && this.policyData[i][allSearchFields[j].dataset.field] != allSearchFields[j].value){
                            recordFiltered=true;
                            break;
                        }
                    }
                }
                if(!recordFiltered){
                    if(this.policyData[i].subTitlte && this.policyData[i].subTitlte!='' && this.typeOptions.findIndex((item) => item.label === this.policyData[i].subTitlte) === -1 ){
                        this.typeOptions.push({ label: this.policyData[i].subTitlte, value: this.policyData[i].subTitlte });
                    }
                    this.tableData.push(this.policyData[i]);
                }
            }
        }
    }
}