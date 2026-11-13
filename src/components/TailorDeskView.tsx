import React, { useRef, useState } from "react";
import {
  Camera,
  CheckCircle2,
  CreditCard,
  Printer,
  Scissors,
  Send,
  ShoppingBag,
} from "lucide-react";
import { HOUSE_ATELIER, ORDER_JOURNEY_STAGES } from "../data/catalog";
import {
  OrderStage,
  PaymentStatus,
  TailoringOrder,
} from "../types";

interface TailorDeskViewProps {
  orders: TailoringOrder[];
  onSetOrderStage: (orderId: string, stage: OrderStage) => void;
  onSetPaymentStatus: (orderId: string, status: PaymentStatus) => void;
  onPostTailorUpdate: (
    orderId: string,
    text: string,
    imageDataUrl?: string
  ) => void;
  onOpenCutSheet: (order: TailoringOrder) => void;
}

const PAYMENT_OPTIONS: PaymentStatus[] = [
  "Deposit pending",
  "50% deposit paid",
  "Paid in full",
];

export const TailorDeskView: React.FC<TailorDeskViewProps> = ({
  orders,
  onSetOrderStage,
  onSetPaymentStatus,
  onPostTailorUpdate,
  onOpenCutSheet,
}) => {
  const [replyDrafts, setReplyDrafts] = useState<Record<string, string>>({});
  const [wipPhotos, setWipPhotos] = useState<Record<string, string>>({});
  const fileRefs = useRef<Record<string, HTMLInputElement | null>>({});

  const activeCount = orders.filter(
    (o) => o.stage !== "Ready for delivery"
  ).length;
  const rushCount = orders.filter((o) => o.isRushOrder).length;

  const handleWipPhotoSelect = (
    orderId: string,
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = e.target.files?.[0];
    if (!file || !file.type.startsWith("image/")) return;
    const reader = new FileReader();
    reader.onload = () => {
      setWipPhotos((prev) => ({
        ...prev,
        [orderId]: reader.result as string,
      }));
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  };

  const handleSendUpdate = (orderId: string) => {
    const text = (replyDrafts[orderId] || "").trim();
    const img = wipPhotos[orderId];
    if (!text && !img) return;
    onPostTailorUpdate(
      orderId,
      text || "Work-in-progress fitting photo uploaded.",
      img
    );
    setReplyDrafts((prev) => ({ ...prev, [orderId]: "" }));
    setWipPhotos((prev) => {
      const next = { ...prev };
      delete next[orderId];
      return next;
    });
  };

  return (
    <div className="max-w-6xl mx-auto px-5 sm:px-6 py-8 space-y-8">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 pb-6 border-b border-[#211D2B]/10">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-[#7654E8]">
            Studio Management · {HOUSE_ATELIER.name}
          </p>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-[#211D2B] mt-1">
            Tailor Studio Desk
          </h1>
          <p className="text-sm text-[#6E687B] mt-1">
            Inspect client measurements, print cutting sheets, update stages, and send WIP fitting photos.
          </p>
        </div>

        <div className="flex items-center gap-6 text-xs text-[#6E687B] tabular-nums">
          <div>
            <span className="block text-lg font-bold text-[#211D2B]">
              {orders.length}
            </span>
            <span>Total Orders</span>
          </div>
          <div>
            <span className="block text-lg font-bold text-[#7654E8]">
              {activeCount}
            </span>
            <span>In Queue</span>
          </div>
          <div>
            <span className="block text-lg font-bold text-[#9F1239]">
              {rushCount}
            </span>
            <span>Rush Deadlines</span>
          </div>
        </div>
      </div>

      {orders.length === 0 ? (
        <div className="rounded-3xl bg-white border border-[#211D2B]/8 p-12 text-center max-w-xl mx-auto space-y-3">
          <ShoppingBag className="w-11 h-11 text-[#7654E8] mx-auto" />
          <h2 className="font-display text-2xl font-bold text-[#211D2B]">
            No incoming client orders yet
          </h2>
          <p className="text-sm text-[#6E687B]">
            When a client submits an order from Book Fitting, their design, Fit Profile, and
            fabric notes appear here ready for cutting.
          </p>
        </div>
      ) : (
        <div className="space-y-6">
          {orders.map((order) => (
            <article
              key={order.id}
              className="bg-white rounded-3xl p-6 sm:p-7 border border-[#211D2B]/8 space-y-6 shadow-[0_8px_24px_rgba(33,29,43,0.04)]"
            >
              <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-6">
                <div className="flex items-start gap-4">
                  <img
                    src={order.outfitImage}
                    alt={order.outfitName}
                    referrerPolicy="no-referrer"
                    className="w-20 h-28 rounded-2xl object-cover bg-[#EAE3FF] shrink-0"
                  />
                  <div className="space-y-1">
                    <p className="text-xs font-mono tabular-nums text-[#6E687B]">
                      {order.id} · {order.createdAt}
                      {order.isRushOrder ? " · Rush Deadline" : ""}
                    </p>
                    <h2 className="font-display text-xl sm:text-2xl font-bold text-[#211D2B]">
                      {order.outfitName}
                    </h2>
                    <p className="text-xs text-[#6E687B]">
                      Profile: <strong className="text-[#211D2B]">{order.fitProfileLabel}</strong>
                      {" · "}Fabric: <strong className="text-[#211D2B]">{order.fabricChoice}</strong>
                    </p>
                    <p className="text-xs text-[#6E687B]">
                      {order.eventDate ? `Event: ${order.eventDate} · ` : ""}
                      {order.appointmentSlot || "Measurements attached"}
                    </p>
                    <p className="text-xs text-[#211D2B] pt-1">
                      Note: {order.fabricNote}
                    </p>
                  </div>
                </div>

                <div className="flex flex-wrap items-center gap-3 shrink-0">
                  <button
                    type="button"
                    onClick={() => onOpenCutSheet(order)}
                    className="px-4 py-2.5 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/15 text-xs font-semibold text-[#211D2B] hover:bg-[#EAE3FF]/60 inline-flex items-center gap-1.5 min-h-[42px]"
                  >
                    <Printer className="w-4 h-4 text-[#7654E8]" />
                    <span>Print Cut-Sheet</span>
                  </button>
                </div>
              </div>

              {/* Measurements & Controls */}
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 pt-4 border-t border-[#211D2B]/8">
                <div className="lg:col-span-5 bg-[#FAF8FC] rounded-2xl p-4 space-y-2">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-[#211D2B]">
                    <Scissors className="w-3.5 h-3.5 text-[#7654E8]" />
                    <span>Cutting Measurements (cm)</span>
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-xs font-mono tabular-nums text-[#211D2B]">
                    <span>Chest {order.measurementsSnapshot.Chest.toFixed(1)}</span>
                    <span>Waist {order.measurementsSnapshot.Waist.toFixed(1)}</span>
                    <span>Hip {order.measurementsSnapshot.Hip.toFixed(1)}</span>
                    <span>
                      Shldr {order.measurementsSnapshot.Shoulder.toFixed(1)}
                    </span>
                    <span>
                      Slv {order.measurementsSnapshot.Sleeve.toFixed(1)}
                    </span>
                    <span>
                      Ins {order.measurementsSnapshot.Inseam.toFixed(1)}
                    </span>
                  </div>
                  {order.tailorGuidance && (
                    <p className="text-[11px] text-[#6E687B] pt-1">
                      {order.tailorGuidance}
                    </p>
                  )}
                </div>

                <div className="lg:col-span-7 grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-[#211D2B] mb-1.5 flex items-center gap-1.5">
                      <CheckCircle2 className="w-3.5 h-3.5 text-[#7654E8]" />
                      <span>Production Stage</span>
                    </label>
                    <select
                      value={order.stage}
                      onChange={(e) =>
                        onSetOrderStage(order.id, e.target.value as OrderStage)
                      }
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-xs font-semibold text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
                    >
                      {ORDER_JOURNEY_STAGES.map((s) => (
                        <option key={s.stage} value={s.stage}>
                          {s.stage}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-[#211D2B] mb-1.5 flex items-center gap-1.5">
                      <CreditCard className="w-3.5 h-3.5 text-[#7654E8]" />
                      <span>Payment Milestone</span>
                    </label>
                    <select
                      value={order.paymentStatus}
                      onChange={(e) =>
                        onSetPaymentStatus(
                          order.id,
                          e.target.value as PaymentStatus
                        )
                      }
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-xs font-semibold text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
                    >
                      {PAYMENT_OPTIONS.map((p) => (
                        <option key={p} value={p}>
                          {p}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              {/* Post WIP Photo / Fitting Note to Client */}
              <div className="pt-4 border-t border-[#211D2B]/8 space-y-3">
                <p className="text-xs font-bold text-[#211D2B]">
                  Send Work-in-Progress Photo or Fitting Update
                </p>
                {wipPhotos[order.id] && (
                  <div className="flex items-center gap-3">
                    <img
                      src={wipPhotos[order.id]}
                      alt="WIP attachment preview"
                      className="w-16 h-16 rounded-xl object-cover border border-[#211D2B]/10"
                    />
                    <button
                      type="button"
                      onClick={() =>
                        setWipPhotos((prev) => {
                          const next = { ...prev };
                          delete next[order.id];
                          return next;
                        })
                      }
                      className="text-xs text-[#9F1239] font-semibold hover:underline"
                    >
                      Remove photo
                    </button>
                  </div>
                )}

                <div className="flex flex-col sm:flex-row gap-2">
                  <input
                    type="text"
                    value={replyDrafts[order.id] || ""}
                    onChange={(e) =>
                      setReplyDrafts((prev) => ({
                        ...prev,
                        [order.id]: e.target.value,
                      }))
                    }
                    placeholder="e.g. Bodice basted for first fitting — let us know how the neckline looks"
                    className="flex-1 px-4 py-2.5 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-xs text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
                  />
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      onClick={() => fileRefs.current[order.id]?.click()}
                      className="px-3.5 py-2.5 rounded-xl bg-[#EAE3FF] text-[#7654E8] text-xs font-semibold inline-flex items-center gap-1.5 min-h-[40px]"
                    >
                      <Camera className="w-4 h-4" />
                      <span>WIP Photo</span>
                    </button>
                    <input
                      ref={(el) => {
                        fileRefs.current[order.id] = el;
                      }}
                      type="file"
                      accept="image/*"
                      onChange={(e) => handleWipPhotoSelect(order.id, e)}
                      className="hidden"
                    />
                    <button
                      type="button"
                      onClick={() => handleSendUpdate(order.id)}
                      className="px-4 py-2.5 rounded-xl bg-[#7654E8] text-white text-xs font-semibold inline-flex items-center gap-1.5 hover:bg-[#6442D6] min-h-[40px]"
                    >
                      <Send className="w-3.5 h-3.5" />
                      <span>Send Update</span>
                    </button>
                  </div>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
};
