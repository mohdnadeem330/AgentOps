import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import populateProjects from "@salesforce/apex/DownloadDocumentsController.getAllActiveProjects";
import getAllDocuments from "@salesforce/apex/DownloadDocumentsController.getAllDocuments";
import getDocumentTypes from "@salesforce/apex/DownloadDocumentsController.getDocumentTypes";


// export default class NavigationService extends NavigationMixin(LightningElement)
export default class DownloadDocuments extends NavigationMixin(LightningElement) {
		@track projectList; @track selectedProject;
		@track isLoading = true;
		@track startDate; @track endDate;
		@track isDisable = true;
		errorString ;
		todayDate;
		documentType; selectedDocuType; documentURL;
		
		connectedCallback(){
				this.todayDate = new Date().toJSON().slice(0, 10);
	
				// calling function at the time of Loading component
				this.populateProjects();
				this.getDocumentTypes();
		}
		
		getDocumentTypes(){
				getDocumentTypes({}).then(results=>{
						this.documentType = results;
						
						if(!this.selectedDocuType && results.length > 0){
                this.selectedDocuType = results[0].value;
            }
				}).catch({})
		}
		
		populateProjects(){
        populateProjects()
        .then(data => {
            this.projectList = data;
            
            if(!this.selectedProject && data.length > 0){
                this.selectedProject = data[0].value;
            }
						this.isLoading = false;
        })
        .catch(error => {
            //console.log(error)
            this.projectList = undefined;
            this.isLoading = false;
        });
    }
		
		handleChange(event){
				this.isDisable = true;
				this.errorString = '';
				console.log(event.target.label);
        var inp = this.template.querySelectorAll("lightning-input");

        inp.forEach(function(element){
            if(element.name == "startDate")
                this.startDate = element.value;

            else if(element.name == "endDate")
                this.endDate = element.value;
        },this);
				
				if(event.target.name == 'projectName'){
						this.selectedProject = event.target.value;
				}else if(event.target.name == 'documentType'){
						this.selectedDocuType = event.target.value;
				}
				
				if(this.selectedProject && this.selectedProject !== undefined && this.selectedProject !== null && this.selectedProject !== '' &&
					 this.selectedDocuType && this.selectedDocuType !== undefined && this.selectedDocuType !== null && this.selectedDocuType !== '' &&
					 this.startDate &&  this.startDate !== undefined &&  this.startDate !== null &&  this.startDate !== '' && 
					 this.endDate && this.endDate !== undefined && this.endDate !== null && this.endDate !== '' ){
						
						if(this.startDate > this.endDate){
								this.errorString = 'Start Date should not be greater than the End Date';
								return;
						}
						if(this.startDate > this.todayDate){
								this.errorString = 'Start Date should not be greater than Today';
								return;
						}
						if(this.endDate > this.todayDate){
								this.errorString = 'End Date should not be greater than Today';
								return;
						}
						this.isDisable = false;
				}
		}
		
		handleDownload(event){
				this.errorString = '';
				this.isLoading = true;
				getAllDocuments({projectId:this.selectedProject, documentType:this.selectedDocuType, startDate:this.startDate, endDate:this.endDate})
					.then(result => {
						if(result){
							if(result.success){
								this.isLoading = false;
								this.isDisable = true;
								this.documentURL = result.url;
									
								const event = new ShowToastEvent({
										title: 'Success!',
										message: result.message,
										variant: 'success'
        				});
        				this.dispatchEvent(event);
								this.navigateToDownloadDocuments();
							}else{
									this.isLoading = false;
									const event = new ShowToastEvent({
										title: 'Error!',
										message: result.message,
										variant : 'error'
        				});
        				this.dispatchEvent(event);
							}
						}else{
								this.isLoading = false;
									const event = new ShowToastEvent({
										title: 'Error!',
										message: 'No Data found',
										variant : 'error'
        				});
        				this.dispatchEvent(event);
						}
				})
				.catch(error => {
						this.isLoading = false;
						this.errorString = error.name + ' : ' + error.message;
        });
		}
		
		navigateToDownloadDocuments() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.documentURL //'https://aldarproperties--pruat.sandbox.my.salesforce.com/sfc/servlet.shepherd/version/download/06825000002VjuzAAC/06825000002W2JdAAK/06825000002W2JiAAK/06825000003R88nAAC/0688d000007T3sAAAS'
            }
        });
    }	
}