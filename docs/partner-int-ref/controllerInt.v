//======================================================================
// TEC-PLUS 带中断机制的顺序硬布线控制器 (Spartan-6 XC6SLX9)
//----------------------------------------------------------------------
// �controller.v 基础上扩展中断响应与返回�//   - 新增指令：OUT(1010) / IRET(1011) / DI(1100) / EI(1101)
//   - 新增引脚：INTR(中断请求,来自 PULSE 按钮) / LIAR(IAR<-PC 存断�
//               / IABUS(IAR->DBUS 取断�
//   - 新增内部触发器：EINT(中断允许) / INTQ(中断请求锁存) / IWAIT(等待入口)
//
// 中断使用流程（对应课�拓展层次——带中断功能的硬布线控制�）：
//   �主程序先执行 EI 开中断 (EINT=1) 并运行；
//   �按一�PULSE 产生中断请求，控制器在下一取指�W1)�中断响应"�//        IAR<-PC 保存断点(LIAR) + 关中�EINT=0) + STOP 暂停等待�//   �操作员用数据开关拨入中断程序入口地址，按 QD�//        该拍 PC<-数据开�SBUS+LPC)，随�RUN 自动取指进入中断程序�//   �中断服务程序末尾�EI 开中断，再 IRET 返回断点(IABUS: PC<-IAR)�//
// 说明：IAR 及其装载/送总线通路�TEC-PLUS(Spartan-6, 200 I/O) 上引出，
//       故直接用 LIAR/IABUS 实现断点保存与返回（EPM7128 因未�LIAR/IABUS
//       需另设替代方案，本平台不受此限）�//======================================================================
module controllerInt (
    // ---------------- 输入 ----------------
    input  wire CLRn,          // 复位（低有效�    
	 input  wire T3,            // 节拍时钟（寄存器装载/触发器采样沿�    
	 input  wire SWA, SWB, SWC, // 模式选择开�    
	 input  wire IR4, IR5, IR6, IR7, // 指令操作�IR7~IR4
    input  wire W1, W2, W3,    // 时序节拍（时序发生器产生�    
	 input  wire C,             // 进位/借位标志
    input  wire Z,             // 结果为零标志
    input  wire INTR,          // 中断请求（PULSE 按钮，高有效脉冲/电平�
    // ---------------- 输出 ----------------
    output reg  LDZ,           // 装载 Z 标志
    output reg  LDC,           // 装载 C 标志
    output reg  CIN,           // ALU 进位输入
    output reg  S0, S1, S2, S3,// ALU 功能选择
    output reg  M,             // ALU 逻辑/算术选择
    output reg  ABUS,          // ALU 结果�DBUS
    output reg  DRW,           // 写通用寄存�    
	 output reg  PCINC,         // PC 自增
    output reg  LPC,           // 装载 PC
    output reg  LAR,           // 装载地址寄存�AR
    output reg  PCADD,         // PC 相对转移（PC+offset�    
	 output reg  ARINC,         // AR 自增
    output reg  SELCTL,        // 手动选址模式（用 SEL 选寄存器�    
	 output reg  MEMW,          // 写存储器
    output reg  STOP,          // 停机 / 暂停等待
    output reg  LIR,           // 装载指令寄存�IR
    output reg  SBUS,          // 数据开关�DBUS
    output reg  MBUS,          // 存储器�DBUS
    output reg  SHORT,         // 拍序：单�    
	 output reg  LONG,          // 拍序：三�    
	 output reg  SEL0, SEL1, SEL2, SEL3, // 手动模式寄存器地址
    output reg  LIAR,          // 装载中断地址寄存�IAR (IAR<-PC 保存断点)
    output reg  IABUS          // IAR �DBUS (IRET �PC<-IAR 返回断点)
);

    //------------------------------------------------------------------
    // 内部信号
    //------------------------------------------------------------------
    wire [2:0] mode = {SWC, SWB, SWA};   // 模式�00 RUN / 100 写寄存器 /
                                         // 011 读寄存器 / 010 读存储器 / 001 写存储器
    wire [3:0] op   = {IR7, IR6, IR5, IR4}; // 操作�
    reg  STO;      // 内部状态触发器（读写寄存器/存储器分步用�    
	 reg  SSTO;     // STO 置位请求（组合产生，供触发器采样�
    // 中断相关触发�
    reg  EINT;     // 中断允许（开中断=1，关中断=0），复位后关中断
    reg  INTQ;     // 中断请求锁存（PULSE 捕获后保持，直到被响应）
    reg  IWAIT;    // 等待中断入口地址（响应完成后�1，装入口后清 0�
    // 模式常量
    localparam RUN     = 3'b000;
    localparam WR_REG  = 3'b100;  // 写寄存器
    localparam RD_REG  = 3'b011;  // 读寄存器
    localparam RD_MEM  = 3'b010;  // 读存储器
    localparam WR_MEM  = 3'b001;  // 写存储器

    // 操作码常�    
	 localparam ADD = 4'b0001, SUB = 4'b0010, AND_= 4'b0011, INC = 4'b0100;
    localparam LD  = 4'b0101, ST  = 4'b0110, JC  = 4'b0111, JZ  = 4'b1000;
    localparam JMP = 4'b1001, OUT = 4'b1010, IRET= 4'b1011, DI  = 4'b1100;
    localparam EI  = 4'b1101, STP = 4'b1110;

    //------------------------------------------------------------------
    // 中断关键事件（组合，供时序块采样，也供组合译码判定分支）
    //   - IWAIT 优先�INTQ：先装入口，装完才允许新的响应�    //   - 二者在 RUN 的取指拍(W1)判定，保证指令原子、只在指令边界响应�    //------------------------------------------------------------------
    wire int_ack  = (mode == RUN) & W1 & INTQ & EINT & ~IWAIT; // 中断响应�    
	 wire int_load = (mode == RUN) & W1 & IWAIT;                // 装入口拍
    wire set_ei   = (mode == RUN) & W2 & (op == EI);           // 执行 EI
    wire set_di   = (mode == RUN) & W2 & (op == DI);           // 执行 DI

    //------------------------------------------------------------------
    // STO 触发器（沿用 controller.v：读写寄存器末步自动清零，T3 下降沿采样）
    //------------------------------------------------------------------
    wire clr_reg = ((mode == WR_REG) | (mode == RD_REG)) & STO & W2;

    always @(negedge T3 or negedge CLRn) begin
        if (!CLRn)          STO <= 1'b0;   // 手动复位
        else if (clr_reg)   STO <= 1'b0;   // 读写寄存器末步，自动回初始�        
		  else if (SSTO)      STO <= 1'b1;   // 置位
        // 其它情况保持（读写存储器反复按时 STO 维持 1�    
		  end

    //------------------------------------------------------------------
    // 中断触发器（�STO 同用 T3 下降沿采样）
    //   采样沿选在 T3↓：T3��IAR/PC 等的装载沿，此刻 LIAR/SBUS/LPC 仍有效�    //   IWAIT/EINT 尚未翻转，先把断�入口锁存完成；随�T3�才更新状态位�    //   避免状态翻转与本拍装载同沿竞争（与 controller.v �STO 处理同理）�    //------------------------------------------------------------------
    always @(negedge T3 or negedge CLRn) begin
        if (!CLRn) begin
            EINT  <= 1'b0;   // 复位后关中断
            INTQ  <= 1'b0;
            IWAIT <= 1'b0;
        end else begin
            // 中断允许 EINT：响应时关中断，EI/DI 指令显式开/�            
				if (int_ack)      EINT <= 1'b0;   // 中断响应自动关中�            
				else if (set_ei)  EINT <= 1'b1;   // EI 开中断
            else if (set_di)  EINT <= 1'b0;   // DI 关中�
            // 中断请求锁存 INTQ：开中断时捕�PULSE，响应后清除
            if (int_ack)              INTQ <= 1'b0;
            else if (INTR & EINT)     INTQ <= 1'b1;

            // 等待入口 IWAIT：响应后置位（存完断点等操作员拨入口），装完清零
            if (int_ack)              IWAIT <= 1'b1;
            else if (int_load)        IWAIT <= 1'b0;
        end
    end

    //------------------------------------------------------------------
    // 组合译码：所有输出默认无效，按模�节拍/操作�中断状态置�    //------------------------------------------------------------------
    always @(*) begin
        // 默认全部无效
        LDZ=0; LDC=0; CIN=0; S0=0; S1=0; S2=0; S3=0; M=0;
        ABUS=0; DRW=0; PCINC=0; LPC=0; LAR=0; PCADD=0; ARINC=0;
        SELCTL=0; MEMW=0; STOP=0; LIR=0; SBUS=0; MBUS=0;
        SHORT=0; LONG=0; SEL0=0; SEL1=0; SEL2=0; SEL3=0;
        LIAR=0; IABUS=0;
        SSTO=0;

        // CLR 态判别：W1=W2=W3=0 时不进入任何分支，全输出无效�        
		  case (mode)
        //==============================================================
        // RUN 模式：中断响�/ 装入�/ 取指(W1) + 执行(W2/W3)
        //==============================================================
        RUN: begin
            if (W1) begin
                //------ 中断处理优先于正常取指，均为单拍(SHORT)，不�W2 ------
                if (IWAIT) begin
                    // 装中断入口：PC<-数据开关。单拍完成后 RUN 自动取指进入 ISR�                    
						  SBUS = 1'b1; LPC = 1'b1; SHORT = 1'b1;
                end
                else if (INTQ & EINT) begin
                    // 中断响应：IAR<-PC 保存断点 + 关中�EINT在时序块�) + 暂停等待入口�                    
						  // 单拍，不�IR，故不误执行旧指令�                    
						  LIAR = 1'b1; STOP = 1'b1; SHORT = 1'b1;
                end
                else begin
                    // 正常取指，所有指令共�                    
						  LIR   = 1'b1;
                    PCINC = 1'b1;
                end
            end
            else if (W2) begin
                case (op)
                ADD: begin // F=A+B, M=0 S=1001 CIN=1
                    M=0; S3=1; S2=0; S1=0; S0=1; CIN=1;
                    ABUS=1; DRW=1; LDZ=1; LDC=1;
                end
                SUB: begin // F=A-B, M=0 S=0110 CIN=0
                    M=0; S3=0; S2=1; S1=1; S0=0; CIN=0;
                    ABUS=1; DRW=1; LDZ=1; LDC=1;
                end
                AND_: begin // F=A·B, M=1 S=1011
                    M=1; S3=1; S2=0; S1=1; S0=1;
                    ABUS=1; DRW=1; LDZ=1;
                end
                INC: begin // F=A+1, M=0 S=0000 CIN=0
                    M=0; S3=0; S2=0; S1=0; S0=0; CIN=0;
                    ABUS=1; DRW=1; LDZ=1; LDC=1;
                end
                LD: begin  // AR<-Rs(F=B), 转三�                    
					 M=1; S3=1; S2=0; S1=1; S0=0;
                    ABUS=1; LAR=1; LONG=1;
                end
                ST: begin  // AR<-Rd(F=A), 转三�                    
					 M=1; S3=1; S2=1; S1=1; S0=1;
                    ABUS=1; LAR=1; LONG=1;
                end
                JC: if (C) PCADD = 1'b1;  // C=1 �PC<-PC+offset
                JZ: if (Z) PCADD = 1'b1;  // Z=1 �PC<-PC+offset
                JMP: begin // PC<-Rd(F=A)
                    M=1; S3=1; S2=1; S1=1; S0=1;
                    ABUS=1; LPC=1;
                end
                OUT: begin // DBUS<-Rs(F=B)，送输出单元显示，不写�                    
					 M=1; S3=1; S2=0; S1=1; S0=0;
                    ABUS=1;
                end
                IRET: begin // 返回断点：PC<-IAR
                     IABUS=1; LPC=1;
                end
                EI:  ; // 开中断：EINT 在时序块置位，本拍无总线动作
                DI:  ; // 关中断：EINT 在时序块清零，本拍无总线动作
                STP: STOP = 1'b1; // 停机
                default: ; // 未定义操作码，无动作
                endcase
            end
            else if (W3) begin
                case (op)
                LD:  begin MBUS=1; DRW=1; end        // Rd<-M[AR]
                ST:  begin M=1; S3=1; S2=0; S1=1; S0=0; // M[AR]<-Rs(F=B)
                           ABUS=1; MEMW=1; end
                default: ; // 其它指令�W3
                endcase
            end
        end

        //==============================================================
        // 写寄存器：STO × (W1/W2) 四步�R0->R1->R2->R3
        //==============================================================
        WR_REG: begin
            if (W1) begin
                SBUS=1; SELCTL=1; DRW=1; STOP=1;
                if (!STO) begin            // �: R0, SEL=0011
                    SEL3=0; SEL2=0; SEL1=1; SEL0=1;
                end else begin             // �: R2, SEL=1001
                    SEL3=1; SEL2=0; SEL1=0; SEL0=1;
                end
            end
            else if (W2) begin
                SBUS=1; SELCTL=1; DRW=1; STOP=1;
                if (!STO) begin            // �: R1, SEL=0100, 置位STO
                    SEL3=0; SEL2=1; SEL1=0; SEL0=0;
                    SSTO=1;
                end else begin             // �: R3, SEL=1110
                    SEL3=1; SEL2=1; SEL1=1; SEL0=0;
                end
            end
        end

        //==============================================================
        // 读寄存器：W1/W2 两步
        //==============================================================
        RD_REG: begin
            if (W1) begin                  // SEL=0001
                SELCTL=1; STOP=1;
                SEL3=0; SEL2=0; SEL1=0; SEL0=1;
            end
            else if (W2) begin             // SEL=1011
                SELCTL=1; STOP=1;
                SEL3=1; SEL2=0; SEL1=1; SEL0=1;
            end
        end

        //==============================================================
        // 读存储器：W1, SHORT, 反复按。STO=0 装地址，STO=1 读数据自�        //==============================================================
        RD_MEM: begin
            if (W1) begin
                SELCTL=1; STOP=1; SHORT=1;
                if (!STO) begin
                    SBUS=1; LAR=1; SSTO=1; // 装地址
                end else begin
                    MBUS=1; ARINC=1;       // 读数� 地址自增
                end
            end
        end

        //==============================================================
        // 写存储器：W1, SHORT, 反复按。STO=0 装地址，STO=1 写数据自�        //==============================================================
        WR_MEM: begin
            if (W1) begin
                SELCTL=1; STOP=1; SHORT=1;
                if (!STO) begin
                    SBUS=1; LAR=1; SSTO=1; // 装地址
                end else begin
                    SBUS=1; MEMW=1; ARINC=1; // 写数� 地址自增
                end
            end
        end

        default: ; // 其它模式组合：无动作
        endcase
    end

endmodule
