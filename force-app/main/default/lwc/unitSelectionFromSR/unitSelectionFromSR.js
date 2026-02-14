import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getServiceRequest from '@salesforce/apex/ServiceRequestService.queryAllFieldsWithExtraFields';
import getCommission from '@salesforce/apex/UnitSelectionFromSRController.getCommission';
import getOutstandingLPC from '@salesforce/apex/UnitSelectionFromSRController.getOutstandingLPC';
import getAllSalesOrders from '@salesforce/apex/UnitSelectionFromSRController.getAllSalesOrders';
import getActiveOffers from '@salesforce/apex/UnitSelectionFromSRController.getActiveOffers';
import getOffer from '@salesforce/apex/UnitSelectionFromSRController.getOffer';
import saveUnitSelection from '@salesforce/apex/UnitSelectionFromSRController.saveUnitSelection';

const COLUMN = [
    { label: 'Project Name', fieldName: 'projectName' },
    { label: 'Unit No', fieldName: 'unitNo' },
    { label: 'Sales Order No', fieldName: 'salesOrderNo' },
    {
        label: 'Selling Price', fieldName: 'sellingPrice', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    {
        label: 'Outstanding Amount', fieldName: 'totalOutstanding', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    }
];

const CANCELLED_COLUMNS = [
    { label: 'Project Name', fieldName: 'projectName' },
    { label: 'Unit No', fieldName: 'unitNo' },
    { label: 'Sales Order No', fieldName: 'salesOrderNo' },
    {
        label: 'Selling Price', fieldName: 'sellingPrice', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    { label: 'Selected Option', fieldName: 'selectedOption' },
    {
        label: 'Loss Calculation', fieldName: 'lossCalculation', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    {
        label: 'Equity Reallocated', fieldName: 'equityRefund', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    }
];

const RETAINED_COLUMNS = [
    { label: 'Project Name', fieldName: 'projectName' },
    { label: 'Unit No', fieldName: 'unitNo' },
    { label: 'Sales Order No', fieldName: 'salesOrderNo' },
    {
        label: 'Selling Price', fieldName: 'sellingPrice', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    {
        label: 'Received Amount', fieldName: 'totalInstallmentReceived', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    {
        label: 'Outstanding Amount', fieldName: 'totalOutstanding', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    }
];

export default class UnitSelectionFromSR extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    @track isMutualCancellation = false;
    @track isFullRefund = false;
    @track isConsolidation = false;
    @track recordTypeName = '';
    @track showFooter = true;
    @track isReadOnly = false;

    @track page1 = true;
    @track page2 = false;
    @track currentPageStep = 'Step1';

    @track projectList = [];
    @track unitList = [];
    @track salesOrderList = [];
    @track selectedIndex = 0;
    @track selectedCancelledIndex = 0;

    @track availableUnitList = [];
    @track initialSelectedUnitList = [];
    @track selectedUnitList = [];
    @track unitSummary = {};
    @track selectedRows = [];
    @track isInitialSelectedUnit = false;
    @track cancelledSelectedUnitList = [];
    @track retainedSelectedUnitList = [];
    @track unitSwapUnit = '';

    @track unitOfferMap = {};
    @track offerOption = [];

    @track columns = [];
    @track cancelledColumns = CANCELLED_COLUMNS;
    @track retainedColumns = RETAINED_COLUMNS;

    @track isLoading = false;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            if (this.recordId && this.recordId.substring(0, 3) == '001') {
                this.showFooter = false;
                this.isReadOnly = true;
                this.columns = JSON.parse(JSON.stringify(COLUMN));
            }
        }
    }

    async connectedCallback() {
        console.log('recordId>>>' + this.recordId);
        if (this.recordId && this.recordId.substring(0, 3) == '001') {
            this.showFooter = false;
            this.isReadOnly = true;
            this.columns = JSON.parse(JSON.stringify(COLUMN));
        } else {
            this.showFooter = true;
            this.isReadOnly = false;
            this.isLoading = true;

            let srIds = [];
            srIds.push(this.recordId);

            await getServiceRequest({
                srIds: srIds
            }).then(result => {
                // console.log('result>>>' + result);
                let tempResult = JSON.parse(JSON.stringify(result));
                if (tempResult[0].HexaBPM__External_Status_Name__c == 'Draft' || tempResult[0].HexaBPM__External_Status_Name__c == 'Submitted' || tempResult[0].HexaBPM__External_Status_Name__c == 'Request Verified' || tempResult[0].HexaBPM__External_Status_Name__c == 'Approved' || tempResult[0].HexaBPM__External_Status_Name__c == 'Swap Recommended') {
                    this.isReadOnly = false;
                } else {
                    this.isReadOnly = true;
                }
                this.isConsolidation = tempResult[0].RecordType.Name == 'Consolidation' ? true : false;
                this.isMutualCancellation = tempResult[0].RecordType.Name == 'Mutual Cancellation' ? true : false;
                this.isFullRefund = (tempResult[0].RecordType.Name == 'Mutual Cancellation' || tempResult[0].RecordType.Name == 'Unit Swap') ? true : false;
                this.recordTypeName = tempResult[0].RecordType.Name;
                if (tempResult[0].SRType__c == 'Unit Swap') {
                    this.unitSwapUnit = tempResult[0].Unit__c;
                }

                let tempColumns = JSON.parse(JSON.stringify(COLUMN));
                if (this.isConsolidation) {
                    tempColumns.push({ label: 'Retained Unit', fieldName: 'retainedUnit', type: 'boolean', editable: true });
                    tempColumns.push({ label: 'Cancelled Unit', fieldName: 'cancelledUnit', type: 'boolean', editable: true });
                }

                this.columns = tempColumns;
                this.isLoading = false;
            }).catch(error => {
                console.error('error>>>' + error);
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            })
        }
        this.getOptions(true);
    }

    async getOptions(isConnectedCallback) {
        this.isLoading = true;
        let unitId = this.recordTypeName == 'Unit Swap' ? this.unitSwapUnit : this.selectedUnit;
        await getAllSalesOrders({
            srId: this.recordId,
            projectName: this.selectedProject,
            unitNo: unitId,
            salesOrderNo: this.selectedSalesOrder
        }).then(result => {
            console.log('result>>>' + result);
            let tempResult = JSON.parse(result);
            console.log('tempResult>>>'+tempResult);

            this.availableUnitList = [];
            this.initialSelectedUnitList = [];
            this.selectedUnitList = [];
            this.retainedSelectedUnitList = [];
            this.cancelledSelectedUnitList = [];

            this.unitList = [{ label: '--None--', value: '' }];
            this.salesOrderList = [{ label: '--None--', value: '' }];

            let index = 0;
            for (let res of tempResult) {
                res = this.updateCalculations(res);
                console.log('res>>>'+JSON.stringify(this.res));
                res.rowIndex = index;
                if (res.Id == null || res.Id == '') {
                    this.availableUnitList.push(res);
                    this.unitList.push({ label: res.unitNo, value: res.unitId });
                    this.salesOrderList.push({ label: res.salesOrderNo, value: res.soId });
                } else {
                    this.initialSelectedUnitList.push(res);
                    this.isInitialSelectedUnit = true;
                    this.selectedUnitList.push(res);
                    index++;
                }
            }
            this.updateUnitSummary();
             console.log('availableUnitList>>>' + JSON.stringify(this.availableUnitList));
             console.log('selectedUnitList>>>' + JSON.stringify(this.selectedUnitList));

            if (isConnectedCallback) {
                this.projectList = [{ label: '--None--', value: '' }];
                let projectNames = '';
                for (let res of tempResult) {
                    if (!projectNames.includes(res.projectName) && (res.Id == null || res.Id == '')) {
                        this.projectList.push({ label: res.projectName, value: res.projectName });
                        projectNames += res.projectName + ',';
                    }
                }
            }

            if (this.recordTypeName == 'Unit Swap') {
                if (this.initialSelectedUnitList.length > 0) {
                    this.selectedUnitList = JSON.parse(JSON.stringify(this.initialSelectedUnitList));
                } else {
                    this.selectedUnitList = JSON.parse(JSON.stringify(this.availableUnitList));
                }
                let evt = {};
                evt.target = {
                    name: 'forward'
                }
                this.handleMenuAction(evt);
            }
            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>' + error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        })
    }

    handleChangeCombobox(event) {
        if (event.target.name == 'ProjectName') {
            this.selectedProject = event.detail.value;
        } else if (event.target.name == 'UnitNumber') {
            this.selectedUnit = event.detail.value;
        } else if (event.target.name == 'SalesOrderNumber') {
            this.selectedSalesOrder = event.detail.value;
        }
        this.getOptions(false);
    }

    selectRow(event) {
        this.selectedUnitList = [];
        this.selectedUnitList = JSON.parse(JSON.stringify(this.initialSelectedUnitList));
        this.selectedRows = [];
        let index = this.selectedUnitList.length;
        for (let unit of event.detail.selectedRows) {
            unit.rowIndex = index;
            this.selectedRows.push(unit.soId);
            this.selectedUnitList.push(unit);
            index++;
        }

        if (this.isConsolidation) {
            this.retainedSelectedUnitList = [];
            this.cancelledSelectedUnitList = [];
            for (let unit of this.selectedUnitList) {
                if (unit.retainedUnit) {
                    this.retainedSelectedUnitList.push(unit);
                } else if (unit.cancelledUnit) {
                    this.cancelledSelectedUnitList.push(unit);
                }
            }
        }
        console.log('this.selectedUnitList>>>' + JSON.stringify(this.selectedUnitList));
    }

    handleOnChange(event) {
        console.log('event.detail.draftValues>>>' + JSON.stringify(event.detail.draftValues));
        let draftValueMap = {};
        for (let draftValue of event.detail.draftValues) {
            if (draftValue.cancelledUnit && draftValue.cancelledUnit == true) {
                draftValueMap[draftValue.soId] = 'cancelledUnit';
            } else if (draftValue.retainedUnit && draftValue.retainedUnit == true) {
                draftValueMap[draftValue.soId] = 'retainedUnit';
            } else {
                draftValueMap[draftValue.soId] = '';
            }
        }

        for (let unit of this.availableUnitList) {
            if (draftValueMap.hasOwnProperty(unit.soId)) {
                unit.retainedUnit = draftValueMap[unit.soId] == 'retainedUnit' ? true : false;
                unit.cancelledUnit = draftValueMap[unit.soId] == 'cancelledUnit' ? true : false;
                if (unit.retainedUnit && unit.cancelledUnit) {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: unit.unitNo + ' cannot selected for Retained and Cancelled',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
            }
        }
        for (let unit of this.selectedUnitList) {
            if (draftValueMap.hasOwnProperty(unit.soId)) {
                unit.retainedUnit = draftValueMap[unit.soId] == 'retainedUnit' ? true : false;
                unit.cancelledUnit = draftValueMap[unit.soId] == 'cancelledUnit' ? true : false;
            }
        }
    }

    async handleMenuAction(event) {
        if (event.target.name == 'forward') {
            let isUnitSelected = this.selectedUnitList && this.selectedUnitList.length > 0 ? true : false;
            if (isUnitSelected) {
                let unitNos = [];
                for (let unit of this.selectedUnitList) {
                    unitNos.push(unit.unitId);
                }
                if (this.isConsolidation) {
                    for (let unit of this.selectedUnitList) {
                        if (unit.retainedUnit && unit.cancelledUnit) {
                            const evt = new ShowToastEvent({
                                title: 'Error',
                                message: unit.unitNo + ' cannot selected for Retained and Cancelled both',
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                            return;
                        } if (!unit.retainedUnit && !unit.cancelledUnit) {
                            const evt = new ShowToastEvent({
                                title: 'Error',
                                message: ' Please select "' + unit.unitNo + '" for Retained or Cancelled',
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                            return;
                        }
                    }

                    this.retainedSelectedUnitList = [];
                    this.cancelledSelectedUnitList = [];
                    for (let unit of this.selectedUnitList) {
                        if (unit.retainedUnit) {
                            this.retainedSelectedUnitList.push(unit);
                        } else if (unit.cancelledUnit) {
                            this.cancelledSelectedUnitList.push(unit);
                        }
                    }

                    if (this.retainedSelectedUnitList.length <= 0) {
                        const evt = new ShowToastEvent({
                            title: 'Error',
                            message: 'Please selecte at least one unit for Retention',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        return;
                    } else if (this.cancelledSelectedUnitList <= 0) {
                        const evt = new ShowToastEvent({
                            title: 'Error',
                            message: 'Please selecte at least one unit for Cancellation',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        return;
                    }
                }
                this.page1 = false;
                this.page2 = true;
                this.currentPageStep = 'Step2';

                this.isLoading = true;
                await getCommission({
                    unitNos: unitNos
                }).then(result => {
                    // console.log('result>>>' + result);
                    let tempResult = JSON.parse(JSON.stringify(result));
                    console.log('@@@tempResultCommision'+tempResult);
                    if (Object.keys(tempResult).length != 0) {
                        for (let unit of this.selectedUnitList) {
                            if (tempResult.hasOwnProperty(unit.unitId) && (unit.Id == undefined || unit.Id == null || unit.Id == '')) {
                                let commission = tempResult[unit.unitId];
                                unit.internalCommission = commission.hasOwnProperty('Internal') ? commission.Internal : 0;
                                unit.externalCommission = commission.hasOwnProperty('External') ? commission.External : 0;
                            }
                        }
                    }

                    this.isLoading = false;
                }).catch(error => {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                })

                this.getOffers();
            } else {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one Unit',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
        } else if (event.target.name == 'back') {
            this.page1 = true;
            this.page2 = false;
            this.currentPageStep = 'Step1';
        }
    }

    async getOffers() {
        this.isLoading = true;
        let unitIds = [];
        for (let unit of this.selectedUnitList) {
            unitIds.push(unit.unitId);
        }
        await getActiveOffers({
            unitIds: unitIds
        }).then(result => {
            console.log('result>>>' + JSON.stringify(result));
            let tempResult = JSON.parse(JSON.stringify(result));

            this.unitOfferMap = tempResult;

            this.offerOption = [];
            if (Object.keys(this.unitOfferMap).length != 0) {
                for (let unitOffer of this.unitOfferMap[this.selectedUnitList[this.selectedIndex].unitId]) {
                    this.offerOption.push({
                        label: unitOffer.Name,
                        value: unitOffer.Id
                    })
                }
            }
            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>' + error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        })
    }

    async handleUnitSelect(event) {
        console.log('index>>>' + event.target.dataset.idx);
        this.selectedIndex = event.target.dataset.rowIndex;
        if (this.isConsolidation) {
            this.selectedCancelledIndex = event.target.dataset.idx;
        }
        
        this.isLoading = true;
        let soId = this.selectedUnitList[this.selectedIndex].soId
        await getOutstandingLPC({
            salesOrderId: soId
        }).then(result => {
            // console.log('result>>>' + result);
            let tempResult = JSON.parse(JSON.stringify(result));

            this.selectedUnitList[this.selectedIndex].outStandingLPC = tempResult;

            this.isLoading = false;
        }).catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        })

        this.offerOption = [];
        if (Object.keys(this.unitOfferMap).length != 0) {
            for (let unitOffer of this.unitOfferMap[this.selectedUnitList[this.selectedIndex].unitId]) {
                this.offerOption.push({
                    label: unitOffer.Name,
                    value: unitOffer.Id
                })
            }
        }
    }

    handleChange(event) {
        let unit = JSON.parse(JSON.stringify(this.selectedUnitList[this.selectedIndex]));
        if (event.target.name == 'isFullRefund') {
            unit.isFullRefund = event.target.checked;
            if (unit.isFullRefund) {
                unit.option1 = false;
                unit.option2 = false;
                unit.option3 = false;
                unit.option4 = false;

                unit.option1 = true;
            }
        } else if (event.target.name == 'option1' || event.target.name == 'option2' || event.target.name == 'option3' || event.target.name == 'option4') {
            unit.option1 = false;
            unit.option2 = false;
            unit.option3 = false;
            unit.option4 = false;

            unit[event.target.name] = event.target.checked;
        } else if (event.target.name == 'offer') {
            unit.selectedOffer = event.detail.value;

            this.getSelectedOffer(unit.selectedOffer);
        } else {
            unit[event.target.name] = parseFloat(event.target.value);
        }
        unit = this.updateCalculations(JSON.parse(JSON.stringify(unit)));
        this.selectedUnitList[this.selectedIndex] = unit;
        this.selectedUnitList = [...this.selectedUnitList];
        if (this.isConsolidation) {
            this.cancelledSelectedUnitList[this.selectedCancelledIndex] = unit;
            this.cancelledSelectedUnitList = [...this.cancelledSelectedUnitList];
        }
        this.updateUnitSummary();
    }

    async getSelectedOffer(offerId) {
        this.isLoading = true;
        await getOffer({
            offerId: offerId
        }).then(result => {
            console.log('result>>>' + JSON.stringify(result));
            if (result.hasOwnProperty('Offers_Lines__r')) {
                let tempResult = JSON.parse(JSON.stringify(result.Offers_Lines__r));

                let unit = JSON.parse(JSON.stringify(this.selectedUnitList[this.selectedIndex]));
                let voucherAmount = 0;
                for (let offer of tempResult) {
                    console.log('offer>>>' + JSON.stringify(offer));
                    if (offer.BudgetTaskName__c == 'ADM Fee') {
                        unit.ADMWaiver = offer.OfferValue__c;
                    } else if (offer.BudgetTaskName__c == 'SC Waiver') {
                        unit.SCWaiver = offer.OfferValue__c;
                    } else if (offer.OfferType__c == 'Rebate') {
                        unit.rebate = offer.OfferValue__c;
                    } else if (offer.OfferType__c == 'Voucher') {
                        voucherAmount += offer.OfferValue__c
                    }
                }
                if (voucherAmount != 0) {
                    unit.voucher = voucherAmount;
                }

                unit = this.updateCalculations(JSON.parse(JSON.stringify(unit)));
                this.selectedUnitList[this.selectedIndex] = unit;
                this.selectedUnitList = [...this.selectedUnitList];
                if (this.isConsolidation) {
                    this.cancelledSelectedUnitList[this.selectedCancelledIndex] = unit;
                    this.cancelledSelectedUnitList = [...this.cancelledSelectedUnitList];
                }
                this.updateUnitSummary();
            }

            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>' + error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        })
    }

    updateCalculations(unit) {
        if (unit.Id != undefined && unit.Id != null && unit.Id != '' && unit.option1 && unit.lossCalculation1 == 0) {
            unit.isFullRefund = true;
        }
        unit.totalNonNegotiableCost = unit.serviceCharge + unit.districtCooling + unit.ADDCAssumption + unit.legalfeesVAT + unit.additionalForfeitedAmount;

        if (unit.sellingPrice != null && unit.sellingPrice != 0) {
            unit.ADMWaiverAmount = parseFloat(((unit.sellingPrice * unit.ADMWaiver) / 100).toFixed(2));
            unit.rebateAmount = parseFloat(((unit.sellingPrice * unit.rebate) / 100).toFixed(2));
            unit.darnaAmount = parseFloat(((unit.sellingPrice * unit.darna) / 100).toFixed(2));
            unit.externalCommissionAmount = parseFloat(((unit.sellingPrice * unit.externalCommission) / 100).toFixed(2));
            unit.internalCommissionAmount = parseFloat(((unit.sellingPrice * unit.internalCommission) / 100).toFixed(2));
        } else {
            unit.ADMWaiverAmount = 0;
            unit.rebateAmount = 0;
            unit.darnaAmount = 0;
            unit.externalCommissionAmount = 0;
            unit.internalCommissionAmount = 0;
            unit.OtherLossCalcutation = 0;
        }
        if (unit.SCWaiver != null && unit.SCWaiver != 0 && unit.anticipatedServiceCharges != null && unit.anticipatedServiceCharges != 0 && unit.escalationServiceCharge != null && unit.escalationServiceCharge != 0) {
            if (unit.SCWaiver > 3) {
                let incrementalSC = 0;
                for (let i = 1; i <= unit.SCWaiver; i++) {
                    incrementalSC += unit.anticipatedServiceCharges;
                    if (i > 3 && unit.escalationServiceCharge != null && unit.escalationServiceCharge != 0) {
                        incrementalSC = parseFloat((incrementalSC + (unit.anticipatedServiceCharges * (unit.escalationServiceCharge / 100))).toFixed(2));
                    }
                }
                unit.SCWaivedAmount = incrementalSC;
            } else {
                unit.SCWaivedAmount = parseFloat((unit.anticipatedServiceCharges * unit.SCWaiver).toFixed(2));
            }
        } else {
            unit.SCWaivedAmount = 0;
        }

        unit.totalFutureResaleCost = parseFloat((unit.ADMWaiverAmount + unit.rebateAmount + unit.darnaAmount + unit.salesSupportCost + unit.voucher + unit.SCWaivedAmount).toFixed(2));
        unit.totalFutureCommission = parseFloat((unit.externalCommissionAmount + unit.internalCommissionAmount).toFixed(2));
        console.log('@@@totalOtherLossCalculation>>>'+unit.OtherLossCalcutation);
        
        unit.totalOtherLossCalculation = unit.OtherLossCalcutation !=undefined ? parseFloat((unit.OtherLossCalcutation).toFixed(2)) :0;

        if (unit.isFullRefund) {
            unit.lossCalculation1 = 0;
            unit.lossCalculation2 = 0;
            unit.lossCalculation3 = 0;
            unit.lossCalculation4 = 0; // Added by Rajat SSR-288
        } else {
            unit.lossCalculation1 = parseFloat((unit.discountValue + unit.totalNonNegotiableCost).toFixed(2));
            unit.lossCalculation2 = parseFloat((unit.discountValue + unit.totalNonNegotiableCost + unit.totalFutureResaleCost).toFixed(2));
            unit.lossCalculation3 = parseFloat((unit.discountValue + unit.totalNonNegotiableCost + unit.totalFutureResaleCost + unit.totalFutureCommission).toFixed(2));
            unit.lossCalculation4 = parseFloat((unit.totalOtherLossCalculation).toFixed(2)); // Added by Rajat ssr-288
        }

        unit.totalInstallmentReceived = unit.totalInstallmentReceived != null ? unit.totalInstallmentReceived : 0;
        unit.equityRefund1 = parseFloat((unit.totalInstallmentReceived - unit.lossCalculation1).toFixed(2));
        unit.equityRefund2 = parseFloat((unit.totalInstallmentReceived - unit.lossCalculation2).toFixed(2));
        unit.equityRefund3 = parseFloat((unit.totalInstallmentReceived - unit.lossCalculation3).toFixed(2));
        unit.equityRefund4 = parseFloat((unit.totalInstallmentReceived - unit.lossCalculation4).toFixed(2));

        if (unit.option1) {
            unit.selectedOption = 'Option 1';
            unit.lossCalculation = unit.lossCalculation1;
            unit.equityRefund = unit.equityRefund1;
        } else if (unit.option2) {
            unit.selectedOption = 'Option 2';
            unit.lossCalculation = unit.lossCalculation2;
            unit.equityRefund = unit.equityRefund2;
        } else if (unit.option3) {
            unit.selectedOption = 'Option 3';
            unit.lossCalculation = unit.lossCalculation3;
            unit.equityRefund = unit.equityRefund3;
        }else if (unit.option4) {
            unit.selectedOption = 'Option 4';
            //unit.lossCalculation = unit.lossCalculation4;  // else if Condition 4 added by Rajat SSR-288
            //unit.equityRefund = unit.equityRefund4;
        } 
        else {
            unit.selectedOption = '';
            unit.lossCalculation = 0;
            unit.equityRefund = 0;
        }
        return unit;
    }

    updateUnitSummary() {
        this.unitSummary = {
            lossCalculation1: 0,
            lossCalculation2: 0,
            lossCalculation3: 0,
            lossCalculation4: 0,
            selectedLossCalculation: 0,
            equityRefund1: 0,
            equityRefund2: 0,
            equityRefund3: 0,
            equityRefund4: 0,
            selectedEquityRefund: 0,
        };
        for (let unit of this.selectedUnitList) {
            this.unitSummary.lossCalculation1 += unit.lossCalculation1; //Lost
            this.unitSummary.lossCalculation2 += unit.lossCalculation2;
            this.unitSummary.lossCalculation3 += unit.lossCalculation3;
            this.unitSummary.lossCalculation4 += unit.lossCalculation4;

            this.unitSummary.equityRefund1 += unit.equityRefund1;
            this.unitSummary.equityRefund2 += unit.equityRefund2;
            this.unitSummary.equityRefund3 += unit.equityRefund3;
            this.unitSummary.equityRefund4 += unit.equityRefund4;

            if (unit.option1) {
                this.unitSummary.selectedLossCalculation += unit.lossCalculation1;
                this.unitSummary.selectedEquityRefund += unit.equityRefund1;
            } else if (unit.option2) {
                this.unitSummary.selectedLossCalculation += unit.lossCalculation2;
                this.unitSummary.selectedEquityRefund += unit.equityRefund2;
            } else if (unit.option3) {
                this.unitSummary.selectedLossCalculation += unit.lossCalculation3;
                this.unitSummary.selectedEquityRefund += unit.equityRefund3;
            }else if (unit.option4) {
                this.unitSummary.selectedLossCalculation += unit.lossCalculation4;
                this.unitSummary.selectedEquityRefund += unit.equityRefund4;
            }
        }
    }

    validateSelectedUnits() {
        this.erroMesssage = '';
        let isSuccess = true;
        console.log('this.selectedUnitList===>'+JSON.stringify(this.selectedUnitList));
        for (let unit of this.selectedUnitList) {
            if (this.isConsolidation && unit.retainedUnit) {
                continue;
            }
            console.log(unit.option1 +' 2 -'+unit.option2+' 3 -'+unit.option3+' 4 -'+unit.option4);
            if (unit.option1 == false && unit.option2 == false && unit.option3 == false && unit.option4 == false) {
                this.erroMesssage += 'Please select at least one option for "' + unit.unitNo + '"';
                isSuccess = false;
            } else {
                let isErrorNonNegotiableCost = false;
                let isErrorFutureResaleCost = false;
                let isErrorFutureCommission = false;
                let isErrorOtherLossCalculation =false;
                if (unit.totalNonNegotiableCost == null || unit.totalNonNegotiableCost == 0) {
                    // isErrorNonNegotiableCost = true;
                }
                if (unit.totalFutureResaleCost == null || unit.totalFutureResaleCost == 0) {
                    isErrorFutureResaleCost = true;
                }
                if (unit.totalFutureCommission == null || unit.totalFutureCommission == 0) {
                    isErrorFutureCommission = true;
                }
                if (unit.totalOtherLossCalculation == null || unit.totalOtherLossCalculation == 0) {
                    isErrorOtherLossCalculation = true;
                }
                if (unit.option1) {
                    if (isErrorNonNegotiableCost) {
                        this.erroMesssage += 'Non Negotiable Cost cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    }
                } else if (unit.option2) {
                    if (isErrorNonNegotiableCost && isErrorFutureResaleCost) {
                        this.erroMesssage += 'Non Negotiable Cost and Future Resale Cost cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorNonNegotiableCost) {
                        this.erroMesssage += 'Non Negotiable Cost cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorFutureResaleCost) {
                        this.erroMesssage += 'Future Resale Cost cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    }
                } else if (unit.option3) {
                    if (isErrorNonNegotiableCost && isErrorFutureResaleCost && isErrorFutureCommission) {
                        this.erroMesssage += 'Non Negotiable Cost, Future Resale Cost and Future Commission cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorNonNegotiableCost && isErrorFutureResaleCost) {
                        this.erroMesssage += 'Non Negotiable Cost and Future Resale Cost cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorNonNegotiableCost && isErrorFutureCommission) {
                        this.erroMesssage += 'Non Negotiable Cost and Future Commission cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorFutureResaleCost && isErrorFutureCommission) {
                        this.erroMesssage += 'Future Resale Cost and Future Commission cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorNonNegotiableCost) {
                        this.erroMesssage += 'Non Negotiable Cost cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorFutureResaleCost) {
                        this.erroMesssage += 'Future Resale Cost cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    } else if (isErrorFutureCommission) {
                        this.erroMesssage += 'Future Commission cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    }
                } else if(unit.option4){
                    if (isErrorOtherLossCalculation) {
                        this.erroMesssage += 'Other Loss Calculation cannot be zero(0) for "' + unit.unitNo + '"';
                        isSuccess = false;
                    }
                }
            }
            if (!isSuccess) {
                break;
            }
        }
        if (this.isConsolidation) {
            let isRetainedUnit = false;
            let isCanceledUnit = false;
            for (let unit of this.selectedUnitList) {
                if (unit.retainedUnit) {
                    isRetainedUnit = true;
                } else if (unit.cancelledUnit) {
                    isCanceledUnit = true;
                }
            }
            if (!isRetainedUnit) {
                this.erroMesssage = 'Please selecte at least one unit for Retention';
                isSuccess = false;
            }
            if (!isCanceledUnit) {
                this.erroMesssage = 'Please selecte at least one unit for Cancellation';
                isSuccess = false;
            }
        }
        return isSuccess;
    }

    async saveUnitDetails() {
        let isSuccess = this.validateSelectedUnits();
        if (isSuccess) {
            let unitSelectionDetails = JSON.stringify(this.selectedUnitList);
            console.log('unitSelectionDetails>>>Save'+unitSelectionDetails);
            this.isLoading = true;
            let recordTypeName = this.isConsolidation ? 'Consolidation' : this.recordTypeName;
             await saveUnitSelection({
                 unitSelectionDetails: unitSelectionDetails,
                 srId: this.recordId,
                 recordTypeName: recordTypeName
             }).then(result => {

                 const evt = new ShowToastEvent({
                     title: 'Success',
                     message: 'Unit(s) are successfully save',
                     variant: 'success',
                 });
                 this.dispatchEvent(evt);
                 window.open('/' + this.recordId, '_self');                
                 this.isLoading = false;
             }).catch(error => {
                 console.error('error>>>' + JSON.stringify(error));
                 const evt = new ShowToastEvent({
                     title: 'Error',
                     message: 'Somthing went wrong. Please contact system Admin.',
                     variant: 'error',
                 });
                 this.dispatchEvent(evt);
                 this.isLoading = false;
             });
        } else {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: this.erroMesssage,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.erroMesssage = '';
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    get hasUnitData() {
        return (this.availableUnitList && this.availableUnitList.length > 0);
    }

    get showSelectedUnits() {
        if (this.isConsolidation) {
            return this.cancelledSelectedUnitList;
        }
        return this.selectedUnitList;
    }

    get hasSelectedUnitList() {
        return (this.selectedUnitList && this.selectedUnitList.length > 1);
    }
}