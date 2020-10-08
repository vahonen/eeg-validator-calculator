function numberStr = convertNumberToString(number, maxStringLength)

numberStr = string(number);
strLength = strlength(numberStr);

if (strLength > maxStringLength)
    if (number < 0)
        nbrLength = strLength - 1;
    else
        nbrLength = strLength;
    end 
    
    exponent = nbrLength - 1;
    mantissa = number*10^-(exponent);
    
    exponentStr = "e" + string(exponent);
    
    allowedMantissaLength = maxStringLength - strlength(exponentStr);
    
    mantissaChar = char(string(mantissa));
    mantissaChar = mantissaChar(1:min(length(mantissaChar), allowedMantissaLength));
    
    numberStr = string(mantissaChar) + exponentStr;
end


end