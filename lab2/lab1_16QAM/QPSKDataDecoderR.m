classdef QPSKDataDecoderR < matlab.System
 
properties (Nontunable)
 FrameSize = 100;
 BarkerLength = 13;
 ModulationOrder = 4;
 DataLength = 174;
 MessageLength = 105;
 DescramblerBase = 2;
 DescramblerPolynomial = [1 1 1 0 1];
 DescramblerInitialConditions = [0 0 0 0];
 PrintOption = false;
 end
 
 properties (Access = private)
 pCorrelator
 pQPSKDemodulator
 pDescrambler
 pBitGenerator
 pErrorRateCalc
 end
 
 properties (Constant, Access = private)
 %pBarkerCode = [+1; +1; +1; +1; +1; -1; -1; +1; +1; -1; +1; -1; +1; +1; +1; +1; +1; +1; -1; -1; +1; +1; -1; +1; -1; +1]; % Bipolar Barker Code 
 %pModulatedHeader = sqrt(2)/2 * (-1-1i) * QPSKDataDecoderR.pBarkerCode;
 %pModulatedHeader = [0.3162-0.3162i; 0.3162-0.9487i; 0.9487-0.3162i; 0.9487-0.9487i; 0.3162+0.3162i; 0.3162+0.9487i; 0.9487+0.3162i; 0.9487+0.9487i; -0.3162-0.3162i; -0.3162-0.9487i; -0.9487-0.3162i; -0.9487-0.9487i; -0.3162+0.3162i; -0.3162+0.9487i; -0.9487+0.3162i; -0.9487+0.9487i];
 pModulatedHeader = [ -0.9487 + 0.9487i, -0.9487 + 0.9487i, -0.3162 + 0.3162i, 0.9487 - 0.9487i, -0.3162 + 0.3162i, -0.3162 + 0.3162i, -0.9487 + 0.9487i, -0.9487 + 0.9487i, -0.9487 + 0.9487i, 0.3162 - 0.3162i, -0.9487 + 0.9487i, 0.9487 - 0.9487i, 0.9487 - 0.9487i]';
 end
 
 methods
 function obj = QPSKDataDecoderR(varargin)
 setProperties(obj,nargin,varargin{:});
 end
 end
 
 methods (Access = protected)
 function setupImpl(obj, ~) 
 obj.pCorrelator = dsp.Crosscorrelator;

 
% obj.pQPSKDemodulator = comm.QPSKDemodulator('PhaseOffset',pi/4, ...
% 'BitOutput', true);
 obj.pQPSKDemodulator = comm.RectangularQAMDemodulator(...
 'ModulationOrder', 16, ...
 'BitOutput', true, ...
 'NormalizationMethod', 'Average power', 'SymbolMapping', 'Custom', ...
 'CustomSymbolMapping', [11 10 14 15 9 8 12 13 1 0 4 5 3 2 6 7]);
 
 obj.pDescrambler = comm.Descrambler(obj.DescramblerBase, ...
 obj.DescramblerPolynomial, obj.DescramblerInitialConditions);
 
 obj.pBitGenerator = QPSKBitsGeneratorR('MessageLength', obj.MessageLength, ...
 'BernoulliLength', obj.DataLength-obj.MessageLength, ...
 'ScramblerBase', obj.DescramblerBase, ...
 'ScramblerPolynomial', obj.DescramblerPolynomial, ...
 'ScramblerInitialConditions', obj.DescramblerInitialConditions);
 
 obj.pErrorRateCalc = comm.ErrorRate; 
 end
 
 function BER = stepImpl(obj, data) 
 % Phase offset estimation
 
 %disp(obj.pModulatedHeader);
 %disp(obj.BarkerLength);
 var1 = conj(obj.pModulatedHeader).*data(1:obj.BarkerLength);
 var2 = angle(mean(var1))*2/pi;
 phaseEst = round(var2)/2*pi;
 
 % Compensating for the phase offset
 phShiftedData = data.*exp(-1i*phaseEst);
 % Demodulating the phase recovered data
 demodOut = step(obj.pQPSKDemodulator, phShiftedData);
 
 % Performs descrambling
 deScrData = step(obj.pDescrambler, ...
 demodOut( ...
 obj.BarkerLength*log2(obj.ModulationOrder)+1 : ...
 obj.FrameSize*log2(obj.ModulationOrder)));
 
 % Recovering the message from the data
 Received = deScrData(1:obj.MessageLength);
 bits2ASCII(obj, Received);
 
 [~, transmittedMessage] = step(obj.pBitGenerator);

 
 BER = step(obj.pErrorRateCalc, transmittedMessage, Received);
 end
 function resetImpl(obj)
 reset(obj.pCorrelator);
 reset(obj.pQPSKDemodulator);
 reset(obj.pDescrambler);
 reset(obj.pBitGenerator);
 reset(obj.pErrorRateCalc);
 end
 
 function releaseImpl(obj)
 release(obj.pCorrelator);
 release(obj.pQPSKDemodulator);
 release(obj.pDescrambler);
 release(obj.pBitGenerator);
 release(obj.pErrorRateCalc);
 end 
 end
 
 methods (Access=private)
 function bits2ASCII(obj,u)
 coder.extrinsic('disp')
 
 % Convert binary-valued column vector to 7-bit decimal values.
 w = [64 32 16 8 4 2 1]; % binary digit weighting
 Nbits = numel(u);
 Ny = Nbits/7;
 y = zeros(1,Ny);
 for i = 0:Ny-1
 y(i+1) = w*u(7*i+(1:7));
 end
 
 % Display ASCII message to command window 
 if(obj.PrintOption)
 disp(char(y));
 end
 end
 end
end