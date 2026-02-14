import { LightningElement, api, wire, track } from 'lwc';
import getAccountSalesOrderData from '@salesforce/apex/CustomerProfileController.getAccountSalesOrderData';
import getInstallmentLines from '@salesforce/apex/CustomerProfileController.getInstallmentLines';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJs';

export default class CustomerProfile extends LightningElement {
    @api recordId;
    @track parentRecord;
    @track salesOrderOptions = [];
    @track salesOrderId;
    @track selectedSalesOrder = '';
    chart;
    chartJsInitialized = false;
    installments = [];
    currentPage = 0;
    entriesPerPage = 3;
    unitDefaultStatus;
    holdFalg;
	flagged;
    activeSalesOrderCount = 0;
    totalSellingPrice = 0;
	totalOutstanding = 0;
	totalSellingPriceFormatted = '';
	totalOutstandingFormatted = '';
	totalAmountCleared = 0;
	totalAmountClearedPercentage = '';
	percentageCollected = '';
    outstandingCount = 0;
    totalCount = 0;
    totalMinusOutstandingCount = 0;  
    upcomingInstallments = 0;
    totalSalesOrderAmount = 0; 
    totalInstallmentReceived = 0;   
    totalInstallmentReceivedPercentage = 0;
    totalOutstandingPercentage = 0;  
    totalInstallmentLines = 0;
    outstandingAmountZero = 0;
    collectedInstallments = '';
    unitSellingPrice = '';
	showChart = false;

    totalOwnedCount;
    fullyPaidCount;
    pendingCount;
    totalTransferCount;
    totalOwnedAmountFormatted;
    fullyPaidAmountFormatted;
    pendingAmountFormatted;
    totalPaidThisYearFormatted;
    totalOutstandingThisYearFormatted;   
	totalInstallmentAmountThisYearFormatted;
    totalTransferSellingPriceFormatted;

    @wire(getAccountSalesOrderData, { accountId: '$recordId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.parentRecord = data;
            this.activeSalesOrderCount = this.parentRecord.salesOrders.length;
			
			
            this.salesOrderOptions = data.salesOrders.map(order => ({
                label: order.Name,
                value: order.Id
            }));			
			this.holdFalg = this.parentRecord.holdFlagCount === 0 ? 'None' : this.parentRecord.holdFlagCount;
			if (this.salesOrderOptions.length > 0) {
                this.showChart = true;
                this.salesOrderId = this.salesOrderOptions[0].value;
                this.handleSalesOrderIdChange({ detail: { value: this.salesOrderId } });
            }
			
			
			
			this.flagged = this.parentRecord.account.Blacklisted__c ? 'True' : 'False';
			
			
			if(this.parentRecord.salesOrders.length > 0){				
			this.totalSellingPrice = this.parentRecord.salesOrders.reduce((sum, order) => {
            return sum + (order.SellingPrice__c || 0);
            }, 0);
			this.totalSellingPriceFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(this.totalSellingPrice);
			this.totalOutstanding = this.parentRecord.salesOrders.reduce((sum, order) => {
                return sum + (order.TotalOutstanding__c || 0);
            }, 0);
			this.totalOutstandingFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(this.totalOutstanding);
			this.totalInstallmentReceived = this.parentRecord.salesOrders.reduce((sum, order) => {
                return sum + (order.TotalInstallmentReceived__c || 0);
            }, 0);
			this.totalInstallmentReceivedPercentage = Math.round((this.totalInstallmentReceived / this.totalSellingPrice) * 100) + '%';
			this.totalAmountCleared = this.parentRecord.salesOrders.reduce((sum, order) => {
            return sum + (order.TotalBilled__c || 0);
            }, 0);
            this.totalAmountClearedPercentage = Math.round((this.totalAmountCleared / this.totalSellingPrice) * 100) + '%';
			if (this.parentRecord.installmentLines.length > 0){
            this.totalInstallmentLines = this.parentRecord.installmentLines.length;
            this.outstandingAmountZero = this.parentRecord.installmentLines.filter(line => line.OutstandingAmount__c === 0).length;
			this.collectedInstallments = this.outstandingAmountZero + '/' + this.totalInstallmentLines;
			} else {
				this.collectedInstallments = 'NIL';				
			}
            }else {
				this.totalAmountClearedPercentage = 'NIL';
				this.collectedInstallments = 'NIL';
				this.totalSellingPriceFormatted = 'NIL';
				this.totalOutstandingFormatted = 'NIL';
				this.totalInstallmentReceivedPercentage = 'NIL'; 
			}

            const salesOrders = data.salesOrders || [];
            const installments = data.installmentLines || [];
            const currentYear = new Date().getFullYear();

            // --- Sales Order Metrics ---
            this.totalOwnedCount = salesOrders.length;
            this.fullyPaidCount = salesOrders.filter(so => (so.TotalOutstanding__c || 0) === 0).length;
            this.pendingCount = salesOrders.filter(so => (so.TotalOutstanding__c || 0) > 0).length;

            const totalOwnedAmount = salesOrders.reduce((sum, so) => sum + (so.NetAmount__c || 0), 0);
            const fullyPaidAmount = salesOrders
                .filter(so => (so.TotalOutstanding__c || 0) === 0)
                .reduce((sum, so) => sum + (so.NetAmount__c || 0), 0);
            const pendingAmount = salesOrders
                .filter(so => (so.TotalOutstanding__c || 0) > 0)
                .reduce((sum, so) => sum + (so.NetAmount__c || 0), 0);

            // --- Installment Metrics ---
            const currentYearInstallments = installments.filter(inst => {
                const instDate = new Date(inst.InstallmentDate__c);
                return instDate.getFullYear() === currentYear;
            });

            //  Total Installment Amount for current year
            const totalInstallmentAmountThisYear = currentYearInstallments
                .reduce((sum, inst) => sum + (inst.InstallmentAmount__c || 0), 0);

            //  Total Paid (where InstallmentAmount__c == AmountReceived__c)
            const totalPaidThisYear = currentYearInstallments
                .reduce((sum, inst) => sum + (inst.InvoicedAmount__c || 0), 0);

            // Total Outstanding (sum of OutstandingAmount__c where not 0)
            const totalOutstandingThisYear = currentYearInstallments
                .filter(inst => (inst.OutstandingAmount__c || 0) !== 0)
                .reduce((sum, inst) => sum + (inst.OutstandingAmount__c || 0), 0);


            const serviceRequests = this.parentRecord.serviceRequests || [];

            var totalTransferSellingPrice = serviceRequests
                .reduce((sum, sr) => sum + (sr.TransferSellingPrice__c || 0), 0);

            this.totalTransferCount = serviceRequests.length;

            // Format with currency
            this.totalOwnedAmountFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(totalOwnedAmount);
            this.fullyPaidAmountFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(fullyPaidAmount);
            this.pendingAmountFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(pendingAmount);
            this.totalPaidThisYearFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(totalPaidThisYear);
            this.totalOutstandingThisYearFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(totalOutstandingThisYear);
            this.totalTransferSellingPriceFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(totalTransferSellingPrice);
            this.totalInstallmentAmountThisYearFormatted = this.parentRecord.currencyIsoCode + ' ' + this.formatAmount(totalInstallmentAmountThisYear);
        } else if (error) {
            console.error(error);
        }		
    }
	
	get roundedRiskScore() {
        return this.parentRecord?.account?.Risk_Score__c ? (Math.round(this.parentRecord.account.Risk_Score__c * 100) / 100).toFixed(2) : null;
    }
	
	get riskLevel() {
        const score = this.parentRecord?.account?.Risk_Score__c ? (Math.round(this.parentRecord.account.Risk_Score__c * 100) / 100).toFixed(2) : null;
		if(score != null){
			if (score >= 0.00 && score <= 2.00) {
            return 'High';
			} else if (score >= 2.01 && score <= 3.00) {
				return 'Medium';
			} else if (score >= 3.01 && score <= 5.00) {
				return 'Low';
			}
        }
        return '';
    }
	
	get age() {
        if (this.parentRecord && this.parentRecord.account.PersonBirthdate) {
            const birthDate = new Date(this.parentRecord.account.PersonBirthdate);
            const today = new Date();
            let age = today.getFullYear() - birthDate.getFullYear();
            const monthDifference = today.getMonth() - birthDate.getMonth();
            if (monthDifference < 0 || (monthDifference === 0 && today.getDate() < birthDate.getDate())) {
                age--;
            }   
            return age;
        }
        return '';
    }
	
	get accountLink() {
        return `/${this.parentRecord.account.Id}`;
    }

    get salesOrderLink() {
        return `/${this.salesOrderId}`;
    }
	
	get unitLink() {
        return `/${this.selectedSalesOrder.Unit__c}`;
    }
	
	formatAmount(amount) {
        if (amount >= 1000000000) {
            return (amount / 1000000000).toFixed(1) + 'B';
        }else if (amount >= 1000000) {
            return (amount / 1000000).toFixed(1) + 'M';
        } else if (amount >= 1000) {
            return (amount / 1000).toFixed(1) + 'K';
        } else {
            return amount.toFixed(2);
        }
    }
	
    handleSalesOrderIdChange(event) {
        this.salesOrderId = event.detail.value;
        this.selectedSalesOrder = this.parentRecord.salesOrders.find(
            order => order.Id === this.salesOrderId
        );
        this.unitSellingPrice = this.selectedSalesOrder.SellingPrice__c ? this.parentRecord.currencyIsoCode + ' ' + this.selectedSalesOrder.SellingPrice__c : null;
        this.unitDefaultStatus = this.selectedSalesOrder.HoldFlag__c ? 'On Hold' : 'Not on Hold';
        this.percentageCollected = Math.round((this.selectedSalesOrder.TotalInstallmentReceived__c / this.selectedSalesOrder.SellingPrice__c) * 100) + '%';
        if (this.salesOrderId) {
            getInstallmentLines({ salesOrderId: this.salesOrderId })
                .then(data => {
                    this.installments = data;
                    this.calculateInstallmentsDueCount();
                    this.outstandingCount = this.installments.filter(inst => inst.OutstandingAmount__c === 0).length;
                    this.totalCount = this.installments.length;
					this.showChart = this.installments.length > 0;
                    this.totalMinusOutstandingCount = this.totalCount - this.outstandingCount;
                    this.upcomingInstallments = this.totalCount - this.installmentsDueCount;
                    this.initializeChart();
                })
                .catch(error => {
                    console.error('Error loading installment data:', error);
                });
        }
    }
    
    calculateInstallmentsDueCount() {
        const today = new Date();
        today.setHours(0, 0, 0, 0); 
        this.installmentsDueCount = this.installments.filter(installment => {
            const installmentDate = new Date(installment.InstallmentDate__c);
            installmentDate.setHours(0, 0, 0, 0);
            return installmentDate <= today;
        }).length;
    }

	
	
	
	
	
	
	
	
    renderedCallback() {
        if (this.chartJsInitialized) {
            return;
        }
        this.chartJsInitialized = true;

        loadScript(this, ChartJS)
            .then(() => {
                
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading Chart.js',
                        message: error.message,
                        variant: 'error'
                    })
                );
            });
    }

    initializeChart() {
        if (this.chart) {
            this.chart.destroy(); 
        }

        const ctx = this.template.querySelector('canvas').getContext('2d');
        const start = this.currentPage * this.entriesPerPage;
        const end = start + this.entriesPerPage;
        const currentInstallments = this.installments.slice(start, end);

        const labels = currentInstallments.map(inst => this.formatLabel(inst.InstallmentDate__c));
        const collected = currentInstallments.map(inst => inst.AmountReceived__c);
        const toBeCollected = currentInstallments.map(inst => inst.OutstandingAmount__c);

      
        const totalCollected = (this.installments.reduce((sum, inst) => sum + (inst.AmountReceived__c || 0), 0)).toFixed(2);
        const totalToBeCollected = (this.installments.reduce((sum, inst) => sum + (inst.OutstandingAmount__c || 0), 0)).toFixed(2);



       
        if (end >= this.installments.length) {
            labels.push('Grand Total');
            collected.push(totalCollected);
            toBeCollected.push(totalToBeCollected);
        }

        this.chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Amount Collected',
                        backgroundColor: 'rgba(0, 128, 0, 1)',
                        data: collected,
                    },
                    {
                        label: 'Amount To Be Collected',
                        backgroundColor: 'rgba(255, 0, 0, 1)',
                        data: toBeCollected,
                    },
                ],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: {
                        stacked: true,
                        grid: { display: false },
                    },
                    y: {
                        stacked: true,
                        beginAtZero: true,
                        title: { display: true, text: 'Amount' },
                        grid: { display: false },
                    },
                },
                plugins: {
                    tooltip: { mode: 'index' },
                    datalabels: {
                        anchor: 'end',
                        align: 'end',
                        formatter: value => value ? value.toFixed(2) : '',
                    },
                },
            },
        });
    }

    formatLabel(dateStr) {
        if (!dateStr || isNaN(new Date(dateStr).getTime())) {
            return 'No Date';  
        }
        const date = new Date(dateStr);
        const month = date.toLocaleString('default', { month: 'long' });
        const year = date.getFullYear();
        return `${month} ${year}`;
    }

    handleNext() {
        if ((this.currentPage + 1) * this.entriesPerPage < this.installments.length) {
            this.currentPage++;
            this.initializeChart();
        }
    }

    handlePrevious() {
        if (this.currentPage > 0) {
            this.currentPage--;
            this.initializeChart();
        }
    }

    get disablePrevious() {
        return this.currentPage === 0;
    }

    get disableNext() {
        return (this.currentPage + 1) * this.entriesPerPage >= this.installments.length;
    }
}