import pandas as pd
import dask.dataframe as dd
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import chest
import copy
import os

def generate_var_list( model_filename, root=None):
    raw_code = open(model_filename, "r")
    model_code = [] 
    for line in raw_code:
        line = line.strip()
        if line:
            model_code.append(line)
    
            
    conditionBoolean = [False, False]
    strings = ["to prepare-behavior-space-output","set final-output"]
    end_char = ")"
    ignore_char = ";"
    var_list=[]
    for line in model_code:
        
        if conditionBoolean[0] and conditionBoolean[1]:
            if ignore_char not in line:
                if (end_char in line):
                    break
                else:
                    var_list.append(line.strip().replace("-"," ").title()) 
                    print(line.strip() + " added to list")   
    
        if (strings[0] in line):        
            print("Found block with vars")
            conditionBoolean[0] = True
        if conditionBoolean[0]:
            if (strings[1] in line):
                conditionBoolean[1] = True
    for i in range(len(var_list)):
        var_list[i] = var_list[i].replace("[", "")    
        var_list[i] = var_list[i].replace("]", "")
                
        print(var_list[i])
    print("list_complete")
    
    return var_list

    
        
def defineExogVar(lst, dct):
    for name in lst:
        dct[name] = np.array([])

def importData(numFiles, name, exogVars, exogValues, orgDict):
    for num in range(1,numFiles + 1):

        dataDict[num] = pd.read_csv(str(num) + name + ".csv", header = 0, index_col=[0],  names = names)#, assume_missing = True)
        generateNewCategories(dataDict[num])
#        print(dataDict[qnum])
        gatherExogValues(exogVars, exogValues, dataDict, num, orgDict)
        print("Import:",num)
    return dataDict

def generateNewCategories(df):
    df["Percent Basic"] = df["Basic"] / df["Population"]
    df["Percent Switcher"] = df["Switcher"] / df["Population"]
    df["Percent Herder"] = df["Herder"] / df["Population"]
    df["Percent Arbitrageur"] = df["Arbitrageur"] / df["Population"]


    df["Basic Wealth Per Capita"] = df["Wealth Basic"] / df["Basic"]
    df["Switcher Wealth Per Capita"] = df["Wealth Switcher"] / df["Switcher"]
    df["Herder Wealth Per Capita"] = df["Wealth Herder"] / df["Herder"]
    df["Arbitrageur Wealth Per Capita"] = df["Wealth Arbitrageur"] / df["Arbitrageur"]
    
    df["Overall Wealth Per Capita"] = (df["Total Sugar"] / df["Sugar Metabolism Scalar"] + df["Total Water"] / df["Water Metabolism Scalar"]) / df["Population"] 



def gatherExogValues(lst, dct, data,num, orgDict):
    orgDict[num] = {}
    for name in lst:    
        val = data[num].loc[1000][name]
        print(name, val)
        
        appVal = np.append(dct[name], data[num].loc[1000][name])
        dct[name] = appVal
        dct[name] = np.round(np.unique(exogValues[name]), decimals = 2)
        appendOrgDict(orgDict, num, val, name)
        
        
def appendOrgDict(orgDict, num, val, name):
    orgDict[num][name] = val
    


def buildDicts(exogValues,exogVars, names,periods, dataDict, trials, TRDEDict, meanValues,varianceDict, stdDevDict, interval):
    for valueTR in exogValues[exogVars[0]]:
        TRDEDict[valueTR] = {}
        meanValues[valueTR] = {}
        varianceDict[valueTR] = {}
        stdDevDict[valueTR] = {}
        for valueDE in exogValues[exogVars[1]]:
            print("Build Dicts:", valueTR, valueDE)
            TRDEDict[valueTR][valueDE] = {}
            meanValues[valueTR][valueDE]= pd.DataFrame(0, index=np.arange(interval, periods + 1, interval), columns=names)
            varianceDict[valueTR][valueDE] = pd.DataFrame(0, index=np.arange(interval,periods+1, interval), columns=names)
            

def resetCountDict(exogValues, exogVars, countDict):
    for valueTR in exogValues[exogVars[0]]:
        countDict[valueTR] = {}
        for valueDE in exogValues[exogVars[1]]:
            countDict[valueTR][valueDE] = 0
        print("Reset Dict:", valueTR, valueDE)

def fillMeanValues(numFiles, exogValues, exogVars, orgDict, TRDEDict, meanValues, countDict):     
    for i in range(1, numFiles+1):
        for valueTR in exogValues[exogVars[0]]:
            for valueDE in exogValues[exogVars[1]]:
                count = countDict[valueTR][valueDE]
                if orgDict[i][exogVars[0]] == valueTR:
                    if orgDict[i][exogVars[1]] == valueDE:
                        TRDEDict[valueTR][valueDE][count] = dataDict[i]
                        meanValues[valueTR][valueDE] += TRDEDict[valueTR][valueDE][count].fillna(0)
                        countDict[valueTR][valueDE] +=1
        print("fillMeanValues:", i)
        
def fillVarianceDict(numFiles, exogValues, exogVars, orgDict, countDict, meanValues):
    for i in range(1, numFiles + 1):
        for valueTR in exogValues[exogVars[0]]:
            for valueDE in exogValues[exogVars[1]]:
                if orgDict[i][exogVars[0]] == valueTR:
                    if orgDict[i][exogVars[1]] == valueDE:
                        count = countDict[valueTR][valueDE]
                        mean = meanValues[valueTR][valueDE]
#                        print(mean)
                        print(count)
#                        print(TRDEDict[valueTR][valueDE][count] )
                        varianceDict[valueTR][valueDE] += (TRDEDict[valueTR][valueDE][count]  - mean) ** 2
                        countDict[valueTR][valueDE] +=1
                stdDevDict[valueTR][valueDE] = varianceDict[valueTR][valueDE] ** (1/2)
        print("Fill Variance Dict:", i)

def normalizeDict(dictionary, exogValues, exogVars, trials):
    for valueTR in exogValues[exogVars[0]]:
        for valueDE in exogValues[exogVars[1]]:
            dictionary[valueTR][valueDE] /= trials
            print("Normalize:", valueTR, valueDE)

def plots(meanValues, stdDevDict, exogValues, primaryExog, secondaryExog, plotGroups, pp):
    for valueTR in exogValues[primaryExog]:
        for valueDE in exogValues[secondaryExog]:
            for group in plotGroups:
                group = plotGroups[group]
                if len(group) == 1:
                    print(group)
                    fig = meanValues[valueTR][valueDE][group].plot.line().get_figure()
                    plt.plot(meanValues[valueTR][valueDE][group] + stdDevDict[valueTR][valueDE][group] * 1.96, color = "k", ls = "--",label = "+/- 1.96 SD")
                    plt.plot(meanValues[valueTR][valueDE][group] - stdDevDict[valueTR][valueDE][group] * 1.96, color = "k", ls = "--")
                    plt.title(group[0] + "\n" + primaryExog + " = " + str(round(valueTR, 3)) + ", " + secondaryExog + " = " + str(round(valueDE, 3)))
                    plt.legend()

                    
                if len(group) > 1:
                    fig = meanValues[valueTR][valueDE][group].plot.line(figsize=(7,5)).get_figure()
                    ax = fig.add_subplot(111)
                    leg = ax.legend(bbox_to_anchor=(1, 1), loc=2)
                    plt.title(primaryExog + " = " + str(round(valueTR, 3)) + ", " + secondaryExog + " = " + str(round(valueDE, 3)))
                    plt.tight_layout()

#                plt.title()
                    
                plt.show()
                pp.savefig(fig, bbox_inches = 'tight')
                plt.close()


def plotGroupsRange(exogValues, exogVar, plotGroups, meanValues, stdDevDict,pp):#primaryExog, secondaryExog, plotGroups, meanValues, stdDevDict,pp):    
    t = 0
    print(exogVar)
    for primeVar in exogVar:
        secondaryExog = copy.deepcopy(exogVar)
        secondaryExog.remove(primeVar)
        secondaryExog = secondaryExog[0]
        for primeVal in exogValues[primeVar]:
            for group in plotGroups:
                subGroup = plotGroups[group]
                if len(subGroup) == 1:
                    fig = plt.figure(figsize=(7,5))
    #                ax = fig.add_subplot(111)
                    for secondVal in exogValues[secondaryExog]:
                    # variable t tracks which index 
                        if t == 0:
                            plt.plot(meanValues[primeVal][secondVal][subGroup], label = secondaryExog + " = " + str(round(secondVal, 3)))
                        if t == 1:
                            plt.plot(meanValues[secondVal][primeVal][subGroup], label = secondaryExog + " = " + str(round(secondVal, 3)))
                            
                    
                    plt.title(str(subGroup[0]) + "\n" + primeVar + " = " + str(round(primeVal, 3)))
                    plt.legend(bbox_to_anchor=(1, 1), loc=2)
                    plt.tight_layout()
                    plt.show()
    
                    pp.savefig(fig, bbox_inches = 'tight')
                    plt.close()
        t += 1
                
def initialize_image(numx, numy):
	image = []
	for i in range(numy):
		x_colors = []
		for j in range(numx):
			x_colors.append(0)
   
		image.append(x_colors)
	return image

def createImageDataFrame(image, title, name,t):            
    if t + 1 == 100:
        folder = "image csvs"
        try:
            os.mkdir(folder)
        except:
            print("Folder "+folder+" already exists")
        df = pd.DataFrame(image)
        df.to_csv(folder + "/" +title + " " + name+ ".csv")        
        
def color_points(title,exogVars, exogValues, mean_values, time, interval,
                  min_val = None, max_val=None ):
#    numx = len(exogVars[])
    cmapPP = PdfPages(title + "cmap.pdf")
    v = 0
    for var in exogVars:
        if v == 0:
            xVar = var
            minValueX, maxValueX = exogValues[var][0], exogValues[var][-1]
            numX = len(exogValues[var])
        if v == 1:
            yVar = var
            minValueY, maxValueY = exogValues[var][0], exogValues[var][-1]
            numY = len(exogValues[var])
        v+=1
    
    for name in names:
#        minValue={}
#        maxValue={}
        for t in range(interval, time+1,interval):
            image = initialize_image(numX, numY)
    
            for i in range(0, numX):
                for j in range(0, numY):
                    # x and y on image[][] is flipped
        #                image[j][i] = mean_values[i][j][category].loc[tick].compute()[0]
#                    mean_values[exogValues[exogVars[0][i]]][exogValues[var][j]][name].loc[t]
                    image[j][i] = mean_values[exogValues[xVar][i]][exogValues[yVar][j]][name].loc[t]

            
            plt.imshow(image, origin='lower', extent=(minValueX, maxValueX,  minValueY, maxValueY),
                       interpolation = 'nearest')
            plt.colorbar()
            plt.clim()#min_val, max_val)
            plt.xlabel(xVar)
            plt.ylabel(yVar)
        #    plt.axes.set_aspect("equal")
            title = name + "\n" +  "Period " + str(t)
            plt.title(title)
            title =title.replace(":","").replace("\n","")
            createImageDataFrame(image, title, name,t)
            
            fig = plt.gcf()
            ax = fig.add_subplot(111)
            ax.set_aspect('auto')
            plt.tight_layout()
            plt.show()
            
            
            plt.draw()
            cmapPP.savefig(fig)
    cmapPP.close()
#    fig.savefig(filename + ".pdf")


def color_points_time_x_axis(time, exogVars,exogValues, mean_values, pp):  #min_value_x, max_value_x, min_value_y,
    minValueX, maxValueX = 0, time
    t = 0                 
    for fixedExog in exogVars:
        for fixedExogVal in exogValues[fixedExog]: 
            for var in exogVars:
                if len(exogValues[var]) > 1:
                    minValueY, maxValueY = exogValues[var][0], exogValues[var][-1]
                    if var != fixedExog:
                        num_y = len(exogValues[var])
                        image = initialize_image(time, num_y)
                        
                        for category in names:
                            for i in range(0, time):
                                for j in range(0, num_y):
                                    # x and y on image[][] is flipped
                                    if t == 0:
                                        image[j][i] = mean_values[fixedExogVal][exogValues[var][j]][category].loc[i]
                                    if t == 1:
                                        image[j][i] = mean_values[exogValues[var][j]][fixedExogVal][category].loc[i]
                            plt.imshow(image, origin='lower', cmap=matplotlib.cm.plasma,
                                       extent=(minValueX, maxValueX,  minValueY, maxValueY), interpolation = 'nearest')
                            plt.colorbar()
                            plt.clim()
                            plt.xlabel("Time")
                        #        plt.xscale("log")
                        #        plt.set_xscale("log")
                            plt.ylabel(var)
                        #    plt.axes.set_aspect("equal")
                            title = category + "\n" + fixedExog + " = " + str(fixedExogVal)
                            plt.title(title)
    #                        plt.title(category + "\n" + fixedExog + " = " + str(fixedExogVal)) # + "\n" + const_1 + " = " + str(y2val) + "\n" + const_2 + " = " + str(c))
                            fig = plt.gcf()
                            ax = fig.add_subplot(111)
                            ax.set_aspect('auto')
                            plt.tight_layout()
                        
                            plt.show()
                            plt.draw()
                            pp.savefig(fig)  
                        t=1
#def gen_new_categories(data, names, newVarSign, target_array):
#    for a in range(len(names):
#        if newVarSign[a] == '+':
#            target_array[self.new_var_names[a]] = target_array[self.new_var_input_1[a]] + target_array[self.new_var_input_2[a]]
#            
#        if self.new_var_sign[a] == '-':
#            target_array[self.new_var_names[a]] = target_array[self.new_var_input_1[a]] - target_array[self.new_var_input_2[a]]
#
#        if self.new_var_sign[a] == '/':
#            target_array[self.new_var_names[a]] = target_array[self.new_var_input_1[a]] / target_array[self.new_var_input_2[a]]
#
#        if self.new_var_sign[a] == '*':
#            target_array[self.new_var_names[a]] = target_array[self.new_var_input_1[a]] * target_array[self.new_var_input_2[a]]
                    

# draw names from nlogo file
names = generate_var_list("Heuristic Sugarscape Visualization.nlogo")
print(names)

## 100 X 100 with 20 trials

numFiles = 25000
trials = 10
interval = 20

## 10 X 10 with 100 trials
#numFiles = 10000
#trials = 100


exogVars = ["Sugar Metabolism Scalar", "Shock Size"]
plotGroups = {}
plotGroups[0] = ["Mean Mutate Rate", "Median Mutate Rate"]
plotGroups[1] = ["Total Sugar", "Total Water"]
plotGroups[2] = ["Mean Sugar Price", "Mean Sugar Price 50 Period Moving Average"]
plotGroups[3] = ["Population"]
plotGroups[4] = ["Mean Sugar Reserve Level", "Mean Water Reserve Level"]
plotGroups[5] = ["Mean Endogenous Rate Of Price Change Of Turtles"]
#plotGroups[6] = ["Basic Only", "Basic Herder", "Basic Arbitrageur", "Basic Herder Arbitrageur"]
#plotGroups[7] = ["Switcher Only", "Switcher Herder", "Switcher Arbitrageur", "Switcher Herder Arbitrageur"]
plotGroups[8] = ["Percent Basic", "Percent Switcher", "Percent Herder", "Percent Arbitrageur"]
plotGroups[9] = ["Basic Wealth Per Capita", "Switcher Wealth Per Capita", "Herder Wealth Per Capita", "Arbitrageur Wealth Per Capita", "Overall Wealth Per Capita"]

#plotGroups[10] = ["Wealth Basic Only","Wealth Basic Herder", "Wealth Basic Arbitrageur", "Wealth Basic Herder Arbitrageur"]
#plotGroups[11] = ["Wealth Switcher Only","Wealth Switcher Herder", "Wealth Switcher Arbitrageur", "Wealth Switcher Herder Arbitrageur"]

countDict = {}
dataDict = {}
orgDict ={}
exogValues = {}
defineExogVar(exogVars, exogValues)
xyDict={}
meanValues = {}
varianceDict = {}
stdDevDict = {}
TRDEDict = {}


# label csv by dimensions of behaviorspacegt
#name = "GA" + year + "TenByTen"
name = "ByTenSugarShockFinal"
#name = "ByHundredSugarShockFinal"
#name = "evenPeriodsReducedSugarShockFinal"

#
pp = PdfPages(name + "linegraphs.pdf")

#import data, map exogenous values
dataDict = importData(numFiles, name, exogVars, exogValues, orgDict)
periods = len(dataDict[1][names[0]]) * interval
names.append("Percent Basic")
names.append("Percent Switcher")
names.append("Percent Herder")
names.append("Percent Arbitrageur")
names.append("Basic Wealth Per Capita")
names.append("Switcher Wealth Per Capita")
names.append("Herder Wealth Per Capita")
names.append("Arbitrageur Wealth Per Capita")   
names.append("Overall Wealth Per Capita")           
buildDicts(exogValues, exogVars, names, periods, trials, dataDict, TRDEDict, meanValues,varianceDict, stdDevDict, interval)   

#Fill Mean Values Dict
resetCountDict(exogValues, exogVars, countDict)    
fillMeanValues(numFiles, exogValues, exogVars, orgDict, TRDEDict, meanValues, countDict)     
normalizeDict(meanValues, exogValues, exogVars, trials)


## uncommnt these if 10 X 10
#Fill Variance Dict

resetCountDict(exogValues, exogVars, countDict)
fillVarianceDict(numFiles, exogValues, exogVars, orgDict, countDict, meanValues)
normalizeDict(varianceDict, exogValues, exogVars, trials)
normalizeDict(stdDevDict, exogValues, exogVars, trials)

print("plottingGroups")

# Only include if 10 X 10
plots(meanValues, stdDevDict, exogValues, exogVars[0], exogVars[1], plotGroups,pp )  
#plotGroupsRange(exogValues, exogVars, plotGroups, meanValues, stdDevDict, pp)
#color_points_time_x_axis(periods, exogVars, exogValues, meanValues, pp)  #min_value_x, max_value_x, min_value_y,
#pp.close()


#color_points(name,exogVars, exogValues, meanValues, periods, interval)




#    
#    
#colNames = generate_var_list("Heuristic Sugarscape.nlogo")
#indexArray = [i * 1000 - 1 for i in range(1,26)]


#for i in range(1,25001):
#    data = pd.read_csv(str(i) + "SugarShockFinal.csv", names=colNames)
#    newData = data.ix[indexArray]
#    newData.to_csv(str(i) + "ReducedSugarShockFinal.csv")

#data = pd.read_csv((str(1) + "ReducedSugarShockFinal.csv"), index_col = [0])
##data.set_index(0, inplace=True)
#print(data)