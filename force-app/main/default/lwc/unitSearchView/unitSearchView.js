import { LightningElement, wire,track } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import searchBuidingUnit from '@salesforce/apex/AFX_CtrlUnitSearch.searchBuidingUnit';
import searchBuidingUnits from '@salesforce/apex/AFX_CtrlUnitSearch.searchBuidingUnits';
import searchUnits from '@salesforce/apex/AFX_CtrlUnitSearch.searchUnits';

const DELAY = 300;

import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

export default class UnitSearchView extends NavigationMixin(LightningElement) {	

   
    @wire(graphql, {
        query: gql`
            query getProjects {
                uiapi {
                    query {
                        Project__c(
                            where: { Name: { ne: null } }
                            first: 100
                            orderBy: { Name: { order: ASC } }
                        ) {
                            edges {
                                node {
                                    Id
                                    Name {
                                        value
                                    } 
                                }
                            }
                        }
                    }
                }
            }
        `
    })
    graphql;
    //get all projects
    get projects() {
        return this.graphql.data?.uiapi.query.Project__c.edges.map((edge) => ({
            value: edge.node.Id,
            label: edge.node.Name.value
        }));
    }

    projectId = '';
    buildingId = '';
    buildings = [];
		buildingUnits ;
		units;
		allUnits ;
		unitData ;
		salesOrderData ;
		 @track error;
	showError = false; 
     handleSearch() {
        try {
            this.buildingUnits =  searchBuidingUnit({ projectId: this.projectId, buildingId:this.buildingId});
            this.buildings =  this.getAllbuildings();
            this.error = undefined;
        } catch (error) {
            this.error = error;
            this.buildingUnits = undefined;
        }
    }

    getAllbuildings(){
        if(this.buildingUnits){
            
            return  this.buildingUnits.lstBuildings.map((edge) => ({
            value: edge.Id,
            label: edge.Name            
        }));        
        }         
    }	
    handleProjectChange(event) {
                      
        this.projectId =  event.target.value;
				
				searchBuidingUnits({ projectId: this.projectId })
						.then((result) => {
						this.buildingUnits = result ;
						this.buildings = result.map((edge) => ({
								value: edge.Id,
								label: edge.Name

						}));					
						console.log('check',this.buildingUnits);
						//this.error = undefined;
				})
						.catch((error) => {
						//this.error = error;
						this.buildingUnits = undefined;
				});
       
    }

    handleBuidingChange(event) {
           
        let searchKey = event.target.value;
				//alert(searchKey);
        
				searchUnits({ buildingId: searchKey })
						.then((result) => {
						this.allUnits = result ; 
						this.units = result.map((edge) => ({
								value: edge.Id,
								label: edge.Name

						}));					
						console.log('check',this.units);
						//this.error = undefined;
				})
						.catch((error) => {
						//this.error = error;
						this.units = undefined;
				});
    }
		handleOpenRecord(event) {
				
				let objId = event.target.dataset.id;			
				//alert(objId);
				this[NavigationMixin.Navigate]({
						type: 'standard__recordPage',
						attributes: {
								recordId: objId,								
								actionName: 'view',							
								
						},
						state: {
								
						},
					});
    }
		 handleUnitChange(event) {
           
         let searchKey = event.target.value;				
				 let noResults = true;				
				 if(this.allUnits){
						 this.allUnits.forEach(unititem => {
								 if(unititem.Id == searchKey ){										
										 if( unititem.OpportunityUnitsUnit__r[0] ){
												 this.showError = false;
												 this.salesOrderData = this.allUnits[0].OpportunityUnitsUnit__r[0] ;			
												 noResults = false;
												 console.log('salsorder',this.allUnits[0].OpportunityUnitsUnit__r[0].Account__r.Name);
												 //alert(this.salesOrderData);								 
										 }
										 this.unitData = unititem; 										 
								 }								
						 });						
				 }
				 if(noResults){
						 this.showError = true;				
						 this.error = "No Salesorder with Sold or Approve Pending foound under the Selected Unit!";						 
						 this.record = undefined;
				 }  
		 }		
}