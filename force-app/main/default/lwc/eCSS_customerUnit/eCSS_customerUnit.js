import { LightningElement, api, wire, track } from "lwc";
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from "lightning/navigation";
//import getCustomerUnits from '@salesforce/apex/ECSS_CustomerUnitController.getCustomerUnits';
import getCustomerUnits from "@salesforce/apex/ECSS_CaseCreationController.getRelatedUnits";
import Customer_Vertical from '@salesforce/schema/Account.CustomerVertical__c';
const actions = [{ label: "Create Case", name: "create_case" }];
export default class ECSS_customerUnit extends NavigationMixin(
  LightningElement
) {
  @api recordId; //accountId
  @track customerUnits = [];
  @track error;
  @track searchTerm = "";
  @track currentPage = 1;
  @track pageSize = 10;
  @track unitsAvailable = false;

  @track projectOptions = [];
  @track filteredProjects = [];
  @track selectedProject;

  @track buildingOptions = [];
  @track filteredBuildings = [];
  @track selectedBuilding;

  @track zoneOptions = [];
  @track filteredZones = [];
  @track selectedZone;
  @track kingsfieldType = '';
  //@track filteredCustUnits =[];

  @track columns = [
    {
      label: "Unit",
      fieldName: "unitNameUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "unitName" }, target: "_blank" },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Unit Code",
      fieldName: "unitCode",
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Unit Type",
      fieldName: "unitType",
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Project",
      fieldName: "projectNameUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "projectNameAttr" },
        target: "_blank"
      },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Zone",
      fieldName: "zoneNameUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "zoneNameAttr" },
        target: "_blank"
      },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Building",
      fieldName: "buildingNameUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "buildingNameAttr" },
        target: "_blank"
      },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Type",
      fieldName: "customerType",
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      type: "button-icon",
      typeAttributes: {
        iconName: "action:new_child_case", // Icon to create a case
        alternativeText: "Create Case",
        title: "Create Case",
        variant: "bare",
        name: "create_case" // Action name for handling click
      }
    }
    /*{
    type: 'action',
    typeAttributes: { rowActions: actions },
    },*/
  ];

  @track flowApiName = "Test_ScreenFLow"; // Replace with your flow's API name
  @track selectedUnitId;

  @track propEzzyCompanyVertical = false;
  @wire(getRecord, { recordId: '$recordId', fields: [Customer_Vertical] })
wiredAccount({ error, data }) {
    if (data) {
        const tempVal = data.fields.CustomerVertical__c.value;
        console.log('TEMP', tempVal);

        const companyVerticals = tempVal ? tempVal.split(';') : [];
        console.log('COMP', companyVerticals);

        // Check for any value that includes 'Kingsfield'
        const kingsfieldValue = companyVerticals.find(val => val.includes('Kingsfield'));

        if (kingsfieldValue) {
            this.propEzzyCompanyVertical = true;
            this.kingsfieldType = kingsfieldValue;
        } else {
            this.propEzzyCompanyVertical = false;
            this.kingsfieldType = null;
        }
    } else if (error) {
        console.error('Error loading account', error);
    }
}
  @wire(getCustomerUnits, { accountId: "$recordId" })
  wiredCustomerUnits({ error, data }) {
    if (data) {
      let unitNameUrl;
      let projectNameUrl;
      let buildingNameUrl;
      let zoneNameUrl;
      let projectNameAttr;
      let buildingNameAttr;
      let zoneNameAttr;
      this.customerUnits = data.map((row) => {
        unitNameUrl = `/${row.unitId}`;
        projectNameUrl = row.projectId ? `/${row.projectId}` : "";
        projectNameAttr = row.projectId ? row.projectName : "";
        buildingNameUrl = row.buildingId ? `/${row.buildingId}` : "";
        buildingNameAttr = row.buildingId ? row.buildingName : "";
        zoneNameUrl = row.zoneId ? `/${row.zoneId}` : "";
        zoneNameAttr = row.zoneId ? row.zoneName : "";
        //projectClass =  row.projectId? 'slds-text-color_default' : 'slds-hide'
        return {
          ...row,
          unitNameUrl,
          projectNameUrl,
          projectNameAttr,
          buildingNameUrl,
          buildingNameAttr,
          zoneNameUrl,
          zoneNameAttr
        };
      });
      //console.log('zz');
      //this.projectOptions.push({ label: '', value: '' });
      data.forEach((item) => {
        // console.log('index'+this.projectOptions.some(option => option.value === item.projectId));
        if (
          item.projectId &&
          !this.projectOptions.some((option) => option.value === item.projectId)
        ) {
          this.projectOptions.push({
            label: item.projectName,
            value: item.projectId
          });
        }
      });
      this.filteredProjects = this.projectOptions;

      //this.buildingOptions.push({ label: '', value: '' });
      data.forEach((item) => {
        if (
          item.buildingId &&
          !this.buildingOptions.some(
            (option) => option.value === item.buildingId
          )
        ) {
          this.buildingOptions.push({
            label: item.buildingName,
            value: item.buildingId,
            projectId: item.projectId,
            zoneId : item.zoneId
          });
        }
      });
      this.filteredBuildings = this.buildingOptions;
      //console.log('BUILDING',this.buildingOptions);

      //this.zoneOptions.push({ label: '', value: '' });
      data.forEach((item) => {
        if (
          item.zoneId &&
          !this.zoneOptions.some((option) => option.value === item.zoneId)
        ) {
          this.zoneOptions.push({ label: item.zoneName, value: item.zoneId, projectId: item.projectId});
        }
      });
      this.filteredZones = this.zoneOptions;
      
      this.error = undefined;
      //console.log(this.customerUnits.length);
      if (this.customerUnits.length === 0) {
        this.unitsAvailable = false;
      } else {
        this.unitsAvailable = true;
      }
      console.log("UnitsAvail" + this.unitsAvailable);
    } else if (error) {
      this.error = error;
      this.customerUnits = [];
      this.unitsAvailable = false;
    }
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    console.log("action:" + actionName);
    if (actionName === "create_case") {
      this.selectedUnitId = row.customerUnitId; // Store selected unit ID if needed
      console.log("SelectedUnit" + this.selectedUnitId);

      /* this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/flow/Test_ScreenFLow?recordId='+this.selectedUnitId // Replace with your flow name
            }
        });*/
      this[NavigationMixin.Navigate]({
        // Pass in pageReference
        type: "standard__component",
        attributes: {
          componentName: "c__eCSS_CaseCreation"
        },
        state: {
          c__recordId: this.selectedUnitId,
          c__accountId: this.recordId
        }
      });
    }
  }

  get totalPages() {
    return Math.ceil(this.filteredUnits.length / this.pageSize);
  }

  get isFirstPage() {
    return this.currentPage === 1;
  }

  get isLastPage() {
    return this.currentPage === this.totalPages;
  }

  get filteredUnits() {
    let searchPattern = this.searchTerm.trim();
    console.log("SEARCHPATT" + searchPattern);
    if (
      !this.selectedProject &&
      !this.selectedZone &&
      !this.selectedBuilding &&
      this.searchTerm === ""
    ) {
      return this.customerUnits;
    } else {
      return this.customerUnits.filter((customerUnit) => {
        const matchesProject = this.selectedProject
          ? customerUnit.projectId === this.selectedProject
          : false;
        const matchesZone = this.selectedZone
          ? customerUnit.zoneId === this.selectedZone
          : false;
        const matchesBuilding = this.selectedBuilding
          ? customerUnit.buildingId === this.selectedBuilding
          : false;
        let matchesUnitName = false;
        let matchesUnitCode = false;
        if (searchPattern !== "") {
          // Handle the wildcard behavior: replace '*' with '.*'
          const regexPattern = searchPattern.replace(/\*/g, ".*").toLowerCase(); // Convert all '*' to regex match
          const regex = new RegExp(regexPattern);
          console.log("regex", regex);
          matchesUnitName = regex.test(customerUnit.unitName.toLowerCase());
          matchesUnitCode = regex.test(customerUnit.unitCode.toLowerCase());
          console.log("mm", matchesUnitName);
        }
        //  const matchesUnitName = this.searchTerm!=''?  customerUnit.unitName.toLowerCase().includes(this.searchTerm.toLowerCase()):false;
        //console.log(matchesUnitName);
        return (
          matchesProject ||
          matchesZone ||
          matchesBuilding ||
          matchesUnitName ||
          matchesUnitCode
        );
      });
    }

    //return this.filteredCustUnits;
    // return this.customerUnits.filter(customerUnit => customerUnit.unitName.toLowerCase().includes(this.searchTerm.toLowerCase()));
    //return this.customerUnits.filter(customerUnit =>customerUnit.projectId === this.selectedProject);
  }

  handleSearch(event) {
    this.searchTerm = event.target.value;
    this.currentPage = 1;
  }
  handleProjectChange(event) {
    this.selectedProject = event.detail.value;
    this.currentPage = 1;
    this.filteredBuildings= this.buildingOptions.filter((option) => option.projectId === this.selectedProject);
    this.filteredZones = this.zoneOptions.filter((option) => option.projectId === this.selectedProject);
    //console.log(this.selectedProject);
  }
  handleBuildingChange(event) {
    this.selectedBuilding = event.detail.value;
   // console.log(event);
    this.currentPage = 1;
    this.filteredProjects = this.projectOptions.filter((x)=> x.value===(this.buildingOptions.find((b) => b.value === this.selectedBuilding).projectId));
    this.filteredZones = this.zoneOptions.filter((x)=> x.value===(this.buildingOptions.find((b) => b.value === this.selectedBuilding).zoneId));

  }
  handleZoneChange(event) {
    this.selectedZone = event.detail.value;
    this.currentPage = 1;
     this.filteredBuildings= this.buildingOptions.filter((option) => option.zoneId === this.selectedZone);
     this.filteredProjects = this.projectOptions.filter((x)=> x.value===(this.zoneOptions.find((b) => b.value === this.selectedZone).projectId));
    
  }
  clearProjectSelection() {
    //console.log('clear');
    this.selectedProject = null;
    this.filteredProjects = this.projectOptions;
    this.filteredZones = this.zoneOptions;
    if(this.selectedZone!=null)
    this.filteredBuildings = this.buildingOptions.filter((option) => option.zoneId === this.selectedZone);
    else
    this.filteredBuildings = this.buildingOptions;
    //this.currentPage = 1;
    //this.filterUnits(); // Reapply filters after clearing
  }
  clearZoneSelection() {
    //console.log('clear');
    this.selectedZone = null;
    this.filteredProjects = this.projectOptions;
    if(this.selectedProject!=null)
    {
      this.filteredZones = this.zoneOptions.filter((option) => option.projectId === this.selectedProject);
      this.filteredBuildings= this.buildingOptions.filter((option) => option.projectId === this.selectedProject);
    }
    else
    {
    this.filteredZones = this.zoneOptions;
    this.filteredBuildings = this.buildingOptions;
    }
    //this.currentPage = 1;
    //this.filterUnits(); // Reapply filters after clearing
  }
  clearBuildingSelection() {
    //console.log('clear');
    this.selectedBuilding = null;
    this.filteredProjects = this.projectOptions;
     if (this.selectedProject!=null)
        this.filteredZones = this.zoneOptions.filter((option) => option.projectId === this.selectedProject);
      else
        this.filteredZones = this.zoneOptions;
    
    if(this.selectedZone!=null)
    {
      this.filteredBuildings= this.buildingOptions.filter((option) => option.zoneId === this.selectedZone);
    }
    else if (this.selectedProject!=null)
    {
      this.filteredBuildings= this.buildingOptions.filter((option) => option.projectId === this.selectedProject);
    }
    else
    {
      this.filteredBuildings= this.buildingOptions;
    }
    //this.currentPage = 1;
    //this.filterUnits(); // Reapply filters after clearing
  }

  handleNextPage() {
    if (!this.isLastPage) {
      this.currentPage++;
    }
  }

  handlePreviousPage() {
    if (!this.isFirstPage) {
      this.currentPage--;
    }
  }

  get paginatedUnits() {
    //console.log('paginated');
    const start = (this.currentPage - 1) * this.pageSize;
    return this.filteredUnits.slice(start, start + this.pageSize);
  }
}